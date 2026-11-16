const jwt = require('jsonwebtoken');
const prisma = require('../config/prisma');

module.exports = async function authMiddleware(req, res, next) {
  try {
    const header = req.headers.authorization || '';
    const [scheme, token] = header.split(' ');
    if (scheme !== 'Bearer' || !token) {
      return res
        .status(401)
        .json({ success: false, message: 'Token tidak ditemukan' });
    }

    const payload = jwt.verify(token, process.env.JWT_SECRET);

    const user = await prisma.user.findUnique({
      where: { id: payload.sub },
      select: { id: true, tokenVersion: true },
    });

    // token invalid jika user hilang atau sudah logout
    if (!user || user.tokenVersion !== payload.tv) {
      return res
        .status(401)
        .json({ success: false, message: 'Sesi tidak valid, silakan login ulang' });
    }

    req.user = { id: user.id };
    next();
  } catch (err) {
    return res
      .status(401)
      .json({ success: false, message: 'Token tidak valid atau kedaluwarsa' });
  }
};