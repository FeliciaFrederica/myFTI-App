const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const prisma = require('../config/prisma');
const AppError = require('../utils/AppError');

const signToken = (user) =>
  jwt.sign(
    { sub: user.id, tv: user.tokenVersion },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );

const sanitizeUser = (user) => ({
  id: user.id,
  fullName: user.fullName,
  email: user.email,
  nim: user.nim,
  wallet: user.wallet
    ? { walletId: user.wallet.walletId, balance: user.wallet.balance }
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
  fullName = fullName.trim();

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
          data: { fullName, nim, email, passwordHash },
        });
        const wallet = await tx.wallet.create({
          data: { walletId: generateWalletId(), userId: created.id, balance: 0 },
        });
        return { ...created, wallet };
      });

      return { token: signToken(user), user: sanitizeUser(user) };
    } catch (err) {
      if (err.code === 'P2002') {
        // Unique constraint: cek apakah karena email/NIM
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
    data: { fullName, ...(email ? { email } : {}) },
    include: { wallet: true },
  });
  return sanitizeUser(user);
}

module.exports = { register, login, logout, getProfile, updateProfile };