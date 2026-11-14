const prisma = require("../../config/prisma");

const PERIODS = ["weekly", "monthly", "yearly"];

// TOP_UP & TRANSFER_IN dihitung sebagai uang masuk, sisanya uang keluar
const INCOME_TYPES = ["TOP_UP", "TRANSFER_IN"];

const createError = (message, statusCode) => {
  const error = new Error(message);
  error.statusCode = statusCode;
  return error;
};

const getRange = (period, now = new Date()) => {
  const from = new Date(now);
  const to = new Date(now);

  if (period === "weekly") {
    const day = (from.getDay() + 6) % 7;
    from.setDate(from.getDate() - day);
  } else if (period === "monthly") {
    from.setDate(1);
  } else {
    from.setMonth(0, 1);
  }

  from.setHours(0, 0, 0, 0);
  to.setHours(23, 59, 59, 999);

  return { from, to };
};

const getFinancialSummary = async (userId, period = "monthly") => {
  if (!userId) {
    throw createError("Mohon login terlebih dahulu.", 401);
  }

  if (!PERIODS.includes(period)) {
    throw createError("Periode harus weekly, monthly, atau yearly.", 400);
  }

  const { from, to } = getRange(period);

  const grouped = await prisma.transaction.groupBy({
    by: ["type"],
    where: {
      userId,
      status: "SUCCESS",
      createdAt: { gte: from, lte: to },
    },
    _sum: { amount: true },
  });

  const breakdown = grouped
    .map((row) => ({ type: row.type, total: row._sum.amount || 0 }))
    .sort((a, b) => b.total - a.total);

  const income = breakdown
    .filter((row) => INCOME_TYPES.includes(row.type))
    .reduce((sum, row) => sum + row.total, 0);

  const expense = breakdown
    .filter((row) => !INCOME_TYPES.includes(row.type))
    .reduce((sum, row) => sum + row.total, 0);

  const total = income + expense;

  return {
    period,
    from,
    to,
    income,
    expense,
    difference: income - expense,
    expensePercentage:
      total === 0 ? 0 : Math.round((expense / total) * 1000) / 10,
    breakdown,
  };
};

module.exports = { getFinancialSummary, PERIODS };
