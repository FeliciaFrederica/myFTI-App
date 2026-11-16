module.exports = (err, req, res, next) => {
  const status = err.statusCode || 500;
  if (status === 500) console.error(err); 
  res.status(status).json({
    success: false,
    message: status === 500 ? 'Terjadi kesalahan pada server' : err.message,
  });
};