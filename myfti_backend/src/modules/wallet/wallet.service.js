const prisma = require("../../config/prisma");
const crypto = require("crypto");
const { notify, formatRupiah } = require("../../utils/notify");

const getWallet = async (userId) => {
  return prisma.wallet.findUnique({
    where: { userId: userId },
    select: { walletId: true, balance: true },
  });
};

const topUp = async (userId, amount) => {
  return await prisma.$transaction(async (tx) => {
    const wallet = await tx.wallet.findUnique({
      where: { userId },
    });

    if (!wallet) { return null; }

    const updatedWallet = await tx.wallet.update({
      where: { userId },
      data: {
        balance: {
          increment: amount,
        },
      },
      select: { walletId: true, balance: true },
    });

    const transaction = await tx.transaction.create({
      data: {
        reference: `TOPUP-${crypto.randomUUID()}`,
        type: "TOP_UP",
        amount,
        description: "Top Up saldo myFTI",
        userId,
      },
    });

    await notify(
      tx,
      userId,
      "Top Up berhasil",
      `Top Up ${formatRupiah(amount)} berhasil ditambahkan ke saldo myFTI.`
    );

    return {
      wallet: updatedWallet,
      transaction,
    };
  });
};

module.exports = {
  getWallet,
  topUp,
};