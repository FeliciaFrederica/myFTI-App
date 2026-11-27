const prisma = require("../../config/prisma");
const { getMerchantDateRange } = require("../summary/merchant-dashboard.service");

const getTransactions = async (
  userId,
  { limit = 10, cursor = null, sort = "desc", from = null, to = null } = {}
) => {
  const where = {
    userId,
    ...(from || to
      ? {
          createdAt: {
            ...(from && { gte: from }),
            ...(to && { lte: to }),
          },
        }
      : {}),
  };

  if (cursor) {
    const cursorTransaction = await prisma.transaction.findFirst({
      where: { id: cursor, ...where },
      select: { id: true },
    });

    if (!cursorTransaction) {
      const error = new Error("Cursor transaksi tidak valid.");
      error.statusCode = 400;
      throw error;
    }
  }

  const transactions = await prisma.transaction.findMany({
    where,
    orderBy: [
      { createdAt: sort === "asc" ? "asc" : "desc" },
      { id: sort === "asc" ? "asc" : "desc" },
    ],
    ...(cursor && {
      cursor: { id: cursor },
      skip: 1,
    }),
    take: limit + 1,
    select: {
      id: true,
      reference: true,
      type: true,
      status: true,
      amount: true,
      description: true,
      subcategory: true,
      counterpartName: true,
      createdAt: true,
    },
  });

  const hasMore = transactions.length > limit;
  const data = hasMore ? transactions.slice(0, limit) : transactions;

  return {
    transactions: data,
    pagination: {
      hasMore,
      nextCursor: hasMore ? data[data.length - 1].id : null,
    },
  };
};

const getMerchantIncomingPayments = async (
  userId,
  {
    limit = 10,
    cursor = null,
    period = "daily",
    from,
    to,
    subcategory,
  } = {}
) => {
  const createdAt = getMerchantDateRange({ period, from, to });
  const where = {
    userId,
    type: "PAYMENT_IN",
    createdAt,
    ...(subcategory ? { subcategory } : {}),
  };

  if (cursor) {
    const cursorTransaction = await prisma.transaction.findFirst({
      where: { id: cursor, ...where },
      select: { id: true },
    });

    if (!cursorTransaction) {
      const error = new Error("Cursor pembayaran tidak valid.");
      error.statusCode = 400;
      throw error;
    }
  }

  const payments = await prisma.transaction.findMany({
    where,
    orderBy: [{ createdAt: "desc" }, { id: "desc" }],
    ...(cursor && { cursor: { id: cursor }, skip: 1 }),
    take: limit + 1,
    select: {
      id: true,
      reference: true,
      type: true,
      status: true,
      amount: true,
      description: true,
      subcategory: true,
      counterpartName: true,
      createdAt: true,
    },
  });

  const hasMore = payments.length > limit;
  const data = hasMore ? payments.slice(0, limit) : payments;

  return {
    transactions: data,
    pagination: {
      hasMore,
      nextCursor: hasMore ? data[data.length - 1].id : null,
    },
  };
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
      subcategory: true,
      counterpartName: true,
      bankCode: true,
      accountNumber: true,
      createdAt: true,
    },
  });
};

module.exports = {
  getTransactions,
  getMerchantIncomingPayments,
  getTransactionDetail,
};
