const bcrypt = require('bcryptjs');

const verifyTransactionPin = async (tx, userId, pin) => {
  if (typeof pin !== 'string' || !/^\d{6}$/.test(pin)) {
    const error = new Error('PIN harus terdiri dari 6 angka');
    error.statusCode = 400;
    throw error;
  }

  const user = await tx.user.findUnique({
    where: { id: userId },
    select: { pinHash: true },
  });

  if (!user) {
    const error = new Error('User tidak ditemukan');
    error.statusCode = 404;
    throw error;
  }

  if (!user.pinHash) {
    const error = new Error('Anda belum memiliki PIN transaksi');
    error.statusCode = 409;
    throw error;
  }

  const isMatch = await bcrypt.compare(pin, user.pinHash);

  if (!isMatch) {
    const error = new Error('PIN transaksi salah');
    error.statusCode = 400;
    throw error;
  }
};

module.exports = verifyTransactionPin;