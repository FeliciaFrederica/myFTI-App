const jwt = require('jsonwebtoken');
const db = require('../config/db');
const AppError = require('../utils/AppError');

module.exports = (req, res, next) => {
  const header = req.headers.authorization || '';
  const [scheme, token] = header.split(' ');
  if (scheme !== 'Bearer' || !token) return next(new AppError('Token tidak ditemukan', 401));

  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    const revoked = db.prepare('SELECT 1 FROM revoked_tokens WHERE jti = ?').get(payload.jti);
    if (revoked) return next(new AppError('Sesi sudah berakhir, silakan login lagi', 401));

    req.user = { id: Number(payload.sub), jti: payload.jti, exp: payload.exp };
    next();
  } catch {
    next(new AppError('Token tidak valid atau kedaluwarsa', 401));
  }
};