const router = require('express').Router();
const rateLimit = require('express-rate-limit');
const c = require('../controllers/auth.controller');
const auth = require('../middleware/auth.middleware');

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  message: { success: false, message: 'Terlalu banyak percobaan, coba lagi nanti' },
});

router.post('/register', limiter, c.register);
router.post('/login', limiter, c.login);
router.post('/logout', auth, c.logout);
router.get('/profile', auth, c.getProfile);
router.put('/profile', auth, c.updateProfile);

module.exports = router;