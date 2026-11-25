const prisma = require("../../config/prisma");

const getTransactions = async (userId) => {
  return prisma.transaction.findMany({
    where: { userId },
    orderBy: { createdAt: "desc" },
    select: {
      id: true,
      reference: true,
      type: true,
      status: true,
      amount: true,
      description: true,
      counterpartName: true,
      createdAt: true,
    },
  });
};

const getTransactionDetail = async (userId, transactionId) => {
  return prisma.transaction.findFirst({
    where: {
      id: transactionId,
      userId,
    },
    select: {
      id: true,
      reference: true,
      type: true,
      status: true,
      amount: true,
      description: true,
      counterpartName: true,
      bankCode: true,
      accountNumber: true,
      createdAt: true,
    },
  });
};

module.exports = { getTransactions, getTransactionDetail };