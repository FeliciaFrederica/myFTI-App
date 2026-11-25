const authService = require('../authentication/auth.service');

const wrap = (fn) => (req, res, next) =>
  Promise.resolve(fn(req, res, next)).catch(next);

exports.register = wrap(async (req, res) => {
  const data = await authService.register(req.body);
  res.status(201).json({ success: true, message: 'Registrasi berhasil', data });
});

exports.login = wrap(async (req, res) => {
  const data = await authService.login(req.body);
  res.json({ success: true, message: 'Login berhasil', data });
});

exports.setupPin = wrap(async (req, res) => {
  await authService.createPin(req.user.id, req.body.pin);

  res.status(201).json({
    success: true,
    message: 'PIN berhasil dibuat',
  });
});

exports.logout = wrap(async (req, res) => {
  await authService.logout(req.user.id);
  res.json({ success: true, message: 'Logout berhasil' });
});

exports.getProfile = wrap(async (req, res) => {
  const data = await authService.getProfile(req.user.id);
  res.json({ success: true, data });
});

exports.updateProfile = wrap(async (req, res) => {
  const data = await authService.updateProfile(req.user.id, req.body);
  res.json({ success: true, message: 'Profil diperbarui', data });
});

// Ganti atau hapus foto profil
exports.updateAvatar = wrap(async (req, res) => {
  const data = await authService.updateAvatar(req.user.id, req.body.avatar);
  res.json({ success: true, message: 'Foto profil diperbarui', data });
});

// Ubah password user yang sedang login
exports.changePassword = wrap(async (req, res) => {
  const { currentPassword, newPassword } = req.body;
  await authService.changePassword(req.user.id, currentPassword, newPassword);
  res.json({ success: true, message: 'Password berhasil diubah' });
});

// ubah pin user yang sedang login
exports.createPinForAuthenticatedUser = wrap(async (req, res) => {
  await authService.createPin(req.user.id, req.body.pin);

  res.status(201).json({
    success: true,
    message: 'PIN berhasil dibuat',
  });
});

exports.changePin = wrap(async (req, res) => {
  const { currentPin, newPin } = req.body;

  await authService.changePin(
    req.user.id,
    currentPin,
    newPin
  );

  res.json({
    success: true,
    message: 'PIN berhasil diubah',
  });
});