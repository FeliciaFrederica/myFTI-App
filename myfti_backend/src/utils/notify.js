const formatRupiah = (amount) => {
  const digits = Math.abs(amount).toString();
  let out = "";

  for (let i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 === 0) out += ".";
    out += digits[i];
  }

  return `Rp ${out}`;
};

const notify = (tx, userId, title, message) =>
  tx.notification.create({ data: { userId, title, message } });

module.exports = { notify, formatRupiah };
