const service = require('../services/auth.service');
const AppError = require('../utils/AppError');
const { validateRegister, validateLogin } = require('../utils/validators');

const wrap = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

exports.register = wrap(async (req, res) => {
  const errors = validateRegister(req.body);
  if (errors.length) throw new AppError(errors.join(', '), 422);
  const data = await service.register(req.body);
  res.status(201).json({ success: true, message: 'Registrasi berhasil', data });
});

exports.login = wrap(async (req, res) => {
  const errors = validateLogin(req.body);
  if (errors.length) throw new AppError(errors.join(', '), 422);
  const data = await service.login(req.body);
  res.json({ success: true, message: 'Login berhasil', data });
});

exports.logout = wrap(async (req, res) => {
  service.logout(req.user);
  res.json({ success: true, message: 'Logout berhasil' });
});

exports.getProfile = wrap(async (req, res) => {
  res.json({ success: true, data: service.getProfile(req.user.id) });
});

exports.updateProfile = wrap(async (req, res) => {
  const { fullName, email } = req.body;
  if (fullName !== undefined && fullName.trim().length < 3) throw new AppError('Nama minimal 3 karakter', 422);
  const data = service.updateProfile(req.user.id, { fullName, email });
  res.json({ success: true, message: 'Profil diperbarui', data });
});