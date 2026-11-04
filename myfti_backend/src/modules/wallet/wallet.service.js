const prisma = require("../../config/prisma");

const getWallet = async (userId) => {
  return prisma.wallet.findUnique({
    where: { userId: userId },
    select: { walletId: true, balance: true },
  });
};

module.exports = {
  getWallet,
};