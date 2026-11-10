const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const db = require('../config/db');
const AppError = require('../utils/AppError');

const DUMMY_HASH = bcrypt.hashSync('dummy-password', 12); // mencegah timing attack

function publicUser(row) {
  return {
    userId: row.id,
    fullName: row.full_name,
    email: row.email,
    nim: row.nim,
    walletId: row.wallet_id,
    balance: row.balance,
  };
}

function signToken(userId) {
  return jwt.sign({}, process.env.JWT_SECRET, {
    subject: String(userId),
    expiresIn: process.env.JWT_EXPIRES_IN || '1d',
    jwtid: crypto.randomUUID(),
  });
}

const findFull = db.prepare(`
  SELECT u.*, w.wallet_id, w.balance
  FROM users u JOIN wallets w ON w.user_id = u.id
  WHERE u.id = ?`);

exports.register = async ({ fullName, nim, email, password }) => {
  email = email.trim().toLowerCase();

  const exists = db.prepare('SELECT email, nim FROM users WHERE email = ? OR nim = ?').get(email, nim);
  if (exists) {
    throw new AppError(exists.email === email ? 'Email sudah terdaftar' : 'NIM sudah terdaftar', 409);
  }

  const passwordHash = await bcrypt.hash(password, 12);

  const create = db.transaction(() => {
    const { lastInsertRowid } = db
      .prepare('INSERT INTO users (full_name, email, nim, password_hash) VALUES (?,?,?,?)')
      .run(fullName.trim(), email, nim, passwordHash);

    const walletId = `FTI${new Date().getFullYear()}${String(lastInsertRowid).padStart(4, '0')}`;
    db.prepare('INSERT INTO wallets (user_id, wallet_id, balance) VALUES (?,?,0)')
      .run(lastInsertRowid, walletId);
    return lastInsertRowid;
  });

  const userId = create();
  return { token: signToken(userId), user: publicUser(findFull.get(userId)) };
};

exports.login = async ({ email, password }) => {
  email = email.trim().toLowerCase();
  const user = db.prepare('SELECT * FROM users WHERE email = ?').get(email);

  const ok = await bcrypt.compare(password, user ? user.password_hash : DUMMY_HASH);
  if (!user || !ok) throw new AppError('Email atau password salah', 401);

  return { token: signToken(user.id), user: publicUser(findFull.get(user.id)) };
};

exports.logout = ({ jti, exp }) => {
  db.prepare('INSERT OR IGNORE INTO revoked_tokens (jti, expires_at) VALUES (?,?)').run(jti, exp);
};

exports.getProfile = (userId) => publicUser(findFull.get(userId));

exports.updateProfile = (userId, { fullName, email }) => {
  const current = db.prepare('SELECT * FROM users WHERE id = ?').get(userId);
  const newEmail = email ? email.trim().toLowerCase() : current.email;

  if (newEmail !== current.email) {
    const taken = db.prepare('SELECT id FROM users WHERE email = ? AND id != ?').get(newEmail, userId);
    if (taken) throw new AppError('Email sudah dipakai pengguna lain', 409);
  }

  db.prepare(`UPDATE users SET full_name = ?, email = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?`)
    .run((fullName || current.full_name).trim(), newEmail, userId);

  return publicUser(findFull.get(userId));
};