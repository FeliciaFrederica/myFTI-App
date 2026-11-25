const router = require('express').Router();
const rateLimit = require('express-rate-limit');
const ctrl = require('../authentication/auth.controller');
const auth = require('../../middlewares/auth.middleware');
const validate = require('../../middlewares/validate.middleware');
const pinSetupAuth = require('../../middlewares/pin-setup.middleware');
const {
  registerSchema,
  loginSchema,
  updateProfileSchema,
  pinSetupSchema,
} = require('../../validators/auth.validator');

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: process.env.NODE_ENV === 'production' ? 10 : 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, message: 'Terlalu banyak percobaan, coba lagi nanti' },
});

const pinSetupLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    message: 'Terlalu banyak percobaan setup PIN, coba lagi nanti',
  },
});

router.post('/register', authLimiter, validate(registerSchema), ctrl.register);
router.post('/login', authLimiter, validate(loginSchema), ctrl.login);
router.post(
  '/pin/setup',
  pinSetupLimiter,
  validate(pinSetupSchema),
  pinSetupAuth,
  ctrl.setupPin
);
router.post('/logout', auth, ctrl.logout);

router.get('/profile', auth, ctrl.getProfile);
router.put('/profile', auth, validate(updateProfileSchema), ctrl.updateProfile);
router.put('/profile/avatar', auth, ctrl.updateAvatar);
router.put('/password', auth, ctrl.changePassword);

module.exports = router;