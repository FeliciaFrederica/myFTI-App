const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const NIM_RE = /^(535|825)\d{6}$/; 

function validateRegister({ fullName, nim, email, password }) {
  const errors = [];
  if (!fullName || fullName.trim().length < 3) errors.push('Nama lengkap minimal 3 karakter');
  if (!NIM_RE.test(nim || '')) errors.push('Format NIM tidak valid');
  if (!EMAIL_RE.test(email || '')) errors.push('Format email tidak valid');
  if (!password || password.length < 8) errors.push('Password minimal 8 karakter');
  else if (!/[A-Za-z]/.test(password) || !/\d/.test(password))
    errors.push('Password harus mengandung huruf dan angka');
  return errors;
}

function validateLogin({ email, password }) {
  const errors = [];
  if (!EMAIL_RE.test(email || '')) errors.push('Format email tidak valid');
  if (!password) errors.push('Password wajib diisi');
  return errors;
}

module.exports = { validateRegister, validateLogin, EMAIL_RE };