const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const prisma = require('../../config/prisma');
const AppError = require('../../utils/AppError');

const signToken = (user) =>
  jwt.sign(
    { sub: user.id, tv: user.tokenVersion },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );

const signPinSetupToken = (user) =>
  jwt.sign(
    {
      sub: user.id,
      tv: user.tokenVersion,
      purpose: 'PIN_SETUP',
    },
    process.env.JWT_SECRET,
    { expiresIn: '10m' }
  );

const sanitizeUser = (user) => ({
  id: user.id,
  fullName: user.fullName,
  email: user.email,
  nim: user.nim,
  role: user.role,
  avatarUrl: user.avatarUrl || null,
  hasPin: Boolean(user.pinHash),
  wallet: user.wallet
    ? {
      walletId: user.wallet.walletId,
      balance: user.wallet.balance
    }
    : null,
});

// Contoh hasil: FTI2026048213
const generateWalletId = () => {
  const year = new Date().getFullYear();
  const rand = crypto.randomInt(0, 1000000);
  return `FTI${year}${String(rand).padStart(6, '0')}`;
};

async function register({ fullName, nim, email, password }) {
  email = email.trim().toLowerCase();
  nim = nim.trim();
  // Nama akan disimpan dalam huruf kapital, contoh: "Budi Santoso" menjadi "BUDI SANTOSO"
  fullName = fullName.trim().toUpperCase();

  const existing = await prisma.user.findFirst({
    where: { OR: [{ email }, { nim }] },
  });
  if (existing) {
    throw new AppError(
      existing.email === email ? 'Email sudah terdaftar' : 'NIM sudah terdaftar',
      409
    );
  }

  const passwordHash = await bcrypt.hash(password, 12);

  for (let attempt = 1; attempt <= 5; attempt++) {
    try {
      const user = await prisma.$transaction(async (tx) => {
        const created = await tx.user.create({
          data: {
            fullName,
            nim,
            email,
            passwordHash,
            role: 'STUDENT',
          },
        });
        const wallet = await tx.wallet.create({
          data: { walletId: generateWalletId(), userId: created.id, balance: 0 },
        });
        return { ...created, wallet };
      });

      return {
        setupToken: signPinSetupToken(user),
        user: sanitizeUser(user),
      };
    } catch (err) {
      if (err.code === 'P2002') {
        const dup = await prisma.user.findFirst({
          where: { OR: [{ email }, { nim }] },
        });
        if (dup) {
          throw new AppError(
            dup.email === email ? 'Email sudah terdaftar' : 'NIM sudah terdaftar',
            409
          );
        }
        if (attempt < 5) continue;
      }
      throw err;
    }
  }
}

async function login({ email, password }) {
  const user = await prisma.user.findUnique({
    where: { email: email.trim().toLowerCase() },
    include: { wallet: true },
  });

  const invalid = new AppError('Email atau password salah', 401);
  if (!user) throw invalid;

  const match = await bcrypt.compare(password, user.passwordHash);
  if (!match) throw invalid;

  return { token: signToken(user), user: sanitizeUser(user) };
}

async function logout(userId) {
  await prisma.user.update({
    where: { id: userId },
    data: { tokenVersion: { increment: 1 } },
  });
}

async function getProfile(userId) {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    include: { wallet: true },
  });
  if (!user) throw new AppError('User tidak ditemukan', 404);
  return sanitizeUser(user);
}

async function updateProfile(userId, { fullName, email }) {
  if (email) {
    email = email.trim().toLowerCase();
    const taken = await prisma.user.findFirst({
      where: { email, NOT: { id: userId } },
    });
    if (taken) throw new AppError('Email sudah dipakai', 409);
  }
  const user = await prisma.user.update({
    where: { id: userId },
    data: {
      ...(fullName ? { fullName: fullName.trim().toUpperCase() } : {}),
      ...(email ? { email } : {}),
    },
    include: { wallet: true },
  });
  return sanitizeUser(user);
}

// Ganti foto profil. Kirim null untuk menghapus foto.
async function updateAvatar(userId, avatar) {
  if (avatar !== null && avatar !== undefined) {
    if (typeof avatar !== 'string' || !avatar.startsWith('data:image/')) {
      throw new AppError('Format foto tidak valid', 400);
    }
    if (avatar.length > 1_500_000) {
      throw new AppError('Ukuran foto terlalu besar', 400);
    }
  }

  const user = await prisma.user.update({
    where: { id: userId },
    data: { avatarUrl: avatar || null },
    include: { wallet: true },
  });
  return sanitizeUser(user);
}

async function changePassword(userId, currentPassword, newPassword) {
  if (!currentPassword || !newPassword) {
    throw new AppError('Password lama dan baru wajib diisi', 400);
  }
  if (newPassword.length < 6) {
    throw new AppError('Password baru minimal 6 karakter', 400);
  }

  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user) throw new AppError('User tidak ditemukan', 404);

  const match = await bcrypt.compare(currentPassword, user.passwordHash);
  if (!match) throw new AppError('Password lama salah', 400);

  const passwordHash = await bcrypt.hash(newPassword, 12);
  await prisma.user.update({
    where: { id: userId },
    data: { passwordHash },
  });
}

async function createPin(userId, pin) {
  const pinHash = await bcrypt.hash(pin, 12);

  const result = await prisma.user.updateMany({
    where: {
      id: userId,
      pinHash: null,
    },
    data: {
      pinHash,
    },
  });

  if (result.count === 0) {
    throw new AppError('PIN sudah pernah dibuat', 409);
  }
}

async function changePin(userId, currentPin, newPin) {
  if (!/^\d{6}$/.test(currentPin) || !/^\d{6}$/.test(newPin)) {
    throw new AppError('PIN harus terdiri dari 6 angka', 400);
  }

  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: {
      pinHash: true,
    },
  });

  if (!user) {
    throw new AppError('User tidak ditemukan', 404);
  }

  if (!user.pinHash) {
    throw new AppError('Anda belum memiliki PIN transaksi', 409);
  }

  const isMatch = await bcrypt.compare(currentPin, user.pinHash);

  if (!isMatch) {
    throw new AppError('PIN lama salah', 400);
  }

  if (currentPin === newPin) {
    throw new AppError('PIN baru tidak boleh sama dengan PIN lama', 400);
  }

  const newPinHash = await bcrypt.hash(newPin, 12);

  const result = await prisma.user.updateMany({
    where: {
      id: userId,
      pinHash: user.pinHash,
    },
    data: {
      pinHash: newPinHash,
    },
  });

  if (result.count === 0) {
    throw new AppError('PIN telah berubah. Silakan coba kembali.', 409);
  }
}

module.exports = {
  register,
  login,
  createPin,
  logout,
  getProfile,
  updateProfile,
  updateAvatar,
  changePassword,
  changePin,
};