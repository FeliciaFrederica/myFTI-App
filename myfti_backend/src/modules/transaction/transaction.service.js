const prisma = require("../../config/prisma");

const getTransactions = async (
  userId,
  { limit = 10, cursor = null, sort = "desc" } = {}
) => {
  if (cursor) {
    const cursorTransaction = await prisma.transaction.findFirst({
      where: { id: cursor, userId },
      select: { id: true },
    });

    if (!cursorTransaction) {
      const error = new Error("Cursor transaksi tidak valid.");
      error.statusCode = 400;
      throw error;
    }
  }

  const transactions = await prisma.transaction.findMany({
    where: { userId },
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

module.exports = { getTransactions };