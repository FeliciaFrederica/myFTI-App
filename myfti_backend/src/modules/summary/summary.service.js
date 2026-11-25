const prisma = require("../../config/prisma");

const PERIODS = ["weekly", "monthly", "yearly"];

// TOP_UP, TRANSFER_IN & PAYMENT_IN dihitung sebagai uang masuk, sisanya uang keluar
const INCOME_TYPES = ["TOP_UP", "TRANSFER_IN", "PAYMENT_IN"];

const MONTH_NAMES = [
  "Jan",
  "Feb",
  "Mar",
  "Apr",
  "Mei",
  "Jun",
  "Jul",
  "Agu",
  "Sep",
  "Okt",
  "Nov",
  "Des",
];

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

const parseDateParam = (value, isEndOfDay = false) => {
  if (typeof value !== "string" || !value.trim()) return null;

  const trimmed = value.trim();
  const ymdMatch = /^(\d{4})-(\d{2})-(\d{2})$/.exec(trimmed);

  let date;
  if (ymdMatch) {
    const year = Number(ymdMatch[1]);
    const month = Number(ymdMatch[2]) - 1;
    const day = Number(ymdMatch[3]);
    date = new Date(year, month, day);
    if (
      date.getFullYear() !== year ||
      date.getMonth() !== month ||
      date.getDate() !== day
    ) {
      return null;
    }
  } else {
    date = new Date(trimmed);
    if (Number.isNaN(date.getTime())) return null;
  }

  if (isEndOfDay) {
    date.setHours(23, 59, 59, 999);
  } else {
    date.setHours(0, 0, 0, 0);
  }

  return date;
};

const getMonthlyComparison = async (userId, monthsCount = 6, now = new Date()) => {
  const startMonth = new Date(now.getFullYear(), now.getMonth() - (monthsCount - 1), 1);
  startMonth.setHours(0, 0, 0, 0);

  const endNow = new Date(now);
  endNow.setHours(23, 59, 59, 999);

  const transactions = await prisma.transaction.findMany({
    where: {
      userId,
      status: "SUCCESS",
      createdAt: { gte: startMonth, lte: endNow },
    },
    select: {
      type: true,
      amount: true,
      createdAt: true,
    },
  });

  const buckets = new Map();
  for (let i = 0; i < monthsCount; i++) {
    const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
    const year = d.getFullYear();
    const month = d.getMonth() + 1;
    const key = `${year}-${String(month).padStart(2, "0")}`;
    buckets.set(key, {
      year,
      month,
      label: `${MONTH_NAMES[month - 1]} ${year}`,
      income: 0,
      expense: 0,
      difference: 0,
    });
  }

  for (const tx of transactions) {
    const dt = new Date(tx.createdAt);
    const key = `${dt.getFullYear()}-${String(dt.getMonth() + 1).padStart(2, "0")}`;
    const bucket = buckets.get(key);
    if (!bucket) continue;

    if (INCOME_TYPES.includes(tx.type)) {
      bucket.income += tx.amount;
    } else {
      bucket.expense += tx.amount;
    }
    bucket.difference = bucket.income - bucket.expense;
  }

  return Array.from(buckets.values());
};

const getFinancialSummary = async (
  userId,
  period = "monthly",
  { from: rawFrom, to: rawTo } = {}
) => {
  if (!userId) {
    throw createError("Mohon login terlebih dahulu.", 401);
  }

  let effectivePeriod = period;
  let from;
  let to;

  if (rawFrom || rawTo) {
    if (!rawFrom || !rawTo) {
      throw createError("Tanggal mulai dan tanggal akhir wajib diisi.", 400);
    }

    from = parseDateParam(rawFrom, false);
    to = parseDateParam(rawTo, true);

    if (!from || !to) {
      throw createError("Format tanggal tidak valid. Gunakan YYYY-MM-DD.", 400);
    }

    if (from > to) {
      throw createError(
        "Tanggal mulai tidak boleh lebih besar dari tanggal akhir.",
        400
      );
    }

    effectivePeriod = "custom";
  } else {
    if (!PERIODS.includes(period)) {
      throw createError("Periode harus weekly, monthly, atau yearly.", 400);
    }

    ({ from, to } = getRange(period));
  }

  const [grouped, monthlyComparison] = await Promise.all([
    prisma.transaction.groupBy({
      by: ["type"],
      where: {
        userId,
        status: "SUCCESS",
        createdAt: { gte: from, lte: to },
      },
      _sum: { amount: true },
    }),
    getMonthlyComparison(userId, 6),
  ]);

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
    period: effectivePeriod,
    from,
    to,
    income,
    expense,
    difference: income - expense,
    expensePercentage:
      total === 0 ? 0 : Math.round((expense / total) * 1000) / 10,
    breakdown,
    monthlyComparison,
  };
};

module.exports = { getFinancialSummary, PERIODS };
