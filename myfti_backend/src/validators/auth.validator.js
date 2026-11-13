const { z } = require('zod');

// NIM FTI: diawali 535 atau 825, total 9 digit (contoh dokumen: 5352500xx)
const nimRegex = /^(535|825)\d{6}$/;

const registerSchema = z.object({
  fullName: z.string().trim().min(3, 'Nama minimal 3 karakter').max(100),
  nim: z.string().trim().regex(nimRegex, 'Format NIM tidak valid'),
  email: z.string().trim().toLowerCase().email('Format email tidak valid'),
  password: z
    .string()
    .min(8, 'Password minimal 8 karakter')
    .regex(/[A-Za-z]/, 'Password harus mengandung huruf')
    .regex(/\d/, 'Password harus mengandung angka'),
});

const loginSchema = z.object({
  email: z.string().trim().toLowerCase().email('Format email tidak valid'),
  password: z.string().min(1, 'Password wajib diisi'),
});

const updateProfileSchema = z.object({
  fullName: z.string().trim().min(3).max(100),
  email: z.string().trim().toLowerCase().email('Format email tidak valid').optional(),
});

module.exports = { registerSchema, loginSchema, updateProfileSchema };