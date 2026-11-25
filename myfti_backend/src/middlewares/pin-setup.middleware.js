const jwt = require('jsonwebtoken');
const prisma = require('../config/prisma');

module.exports = async function pinSetupMiddleware(req, res, next) {
  try {
    const header = req.headers.authorization || '';
    const [scheme, token] = header.split(' ');

    if (scheme !== 'Bearer' || !token) {
      return res.status(401).json({
        success: false,
        message: 'Token setup PIN tidak ditemukan',
      });
    }

    const payload = jwt.verify(token, process.env.JWT_SECRET);

    if (payload.purpose !== 'PIN_SETUP') {
      return res.status(401).json({
        success: false,
        message: 'Token tidak memiliki akses setup PIN',
      });
    }

    const user = await prisma.user.findUnique({
      where: { id: payload.sub },
      select: {
        id: true,
        tokenVersion: true,
        pinHash: true,
      },
    });

    if (!user || user.tokenVersion !== payload.tv) {
      return res.status(401).json({
        success: false,
        message: 'Token setup PIN tidak valid',
      });
    }

    if (user.pinHash) {
      return res.status(409).json({
        success: false,
        message: 'PIN sudah pernah dibuat',
      });
    }

    req.user = { id: user.id };
    next();
  } catch (err) {
    return res.status(401).json({
      success: false,
      message: 'Token setup PIN tidak valid atau kedaluwarsa',
    });
  }
};