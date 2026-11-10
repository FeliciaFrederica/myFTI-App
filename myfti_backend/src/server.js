require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');

if (!process.env.JWT_SECRET || process.env.JWT_SECRET.length < 32) {
  console.error('JWT_SECRET belum diset / terlalu pendek (min 32 karakter) di .env');
  process.exit(1);
}

const app = express();
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '10kb' }));

app.get('/api/health', (req, res) => res.json({ success: true, message: 'myFTI API hidup' }));
app.use('/api/auth', require('./routes/auth.routes'));

app.use((req, res) => res.status(404).json({ success: false, message: 'Endpoint tidak ditemukan' }));

app.use((req, res) => {
  console.log('404 ->', req.method, req.originalUrl);
  res.status(404).json({
    success: false,
    message: `Endpoint tidak ditemukan: ${req.method} ${req.originalUrl}`,
  });
});

app.use((err, req, res, next) => {
  const status = err.status || 500;
  if (status === 500) console.error(err);
  res.status(status).json({
    success: false,
    message: status === 500 ? 'Terjadi kesalahan pada server' : err.message,
  });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => console.log(`myFTI API jalan di port ${PORT}`));