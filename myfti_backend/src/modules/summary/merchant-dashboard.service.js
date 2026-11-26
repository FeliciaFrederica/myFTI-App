const prisma = require("../../config/prisma");

const WIB_OFFSET_MS = 7 * 60 * 60 * 1000;

const getWibParts = (date) => {
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone: "Asia/Jakarta",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).formatToParts(date);

  return Object.fromEntries(parts.map(({ type, value }) => [type, value]));
};

const wibMidnight = (year, month, day) =>
  new Date(Date.UTC(year, month - 1, day) - WIB_OFFSET_MS);

const getWibDay = (date) => {
  const { year, month, day } = getWibParts(date);
  return wibMidnight(Number(year), Number(month), Number(day));
};

const parseWibDate = (value) => {
  if (typeof value !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    return null;
  }
  const [year, month, day] = value.split("-").map(Number);
  const date = wibMidnight(year, month, day);
  const check = getWibParts(date);
  if (
    Number(check.year) !== year ||
    Number(check.month) !== month ||
    Number(check.day) !== day
  ) {
    return null;
  }
  return date;
};

const getMerchantDateRange = (
  { period = "daily", from, to } = {},
  now = new Date()
) => {
  if (period === "custom") {
    const start = parseWibDate(from);
    const end = parseWibDate(to);
    if (!start || !end || start > end) {
      const error = new Error("Rentang tanggal merchant tidak valid.");
      error.statusCode = 400;
      throw error;
    }
    return { gte: start, lt: new Date(getWibDay(end).getTime() + 86400000) };
  }

  const today = getWibDay(now);
  const tomorrow = new Date(today.getTime() + 86400000);
  const weekday = new Date(today.getTime() + WIB_OFFSET_MS).getUTCDay();
  const daysSinceMonday = (weekday + 6) % 7;

  switch (period) {
    case "daily":
      return { gte: today, lt: tomorrow };
    case "weekly":
      return {
        gte: new Date(today.getTime() - daysSinceMonday * 86400000),
        lt: tomorrow,
      };
    case "monthly": {
      const { year, month } = getWibParts(now);
      return { gte: wibMidnight(Number(year), Number(month), 1), lt: tomorrow };
    }
    case "yearly": {
      const { year } = getWibParts(now);
      return { gte: wibMidnight(Number(year), 1, 1), lt: tomorrow };
    }
    default: {
      const error = new Error("Periode harus daily, weekly, monthly, yearly, atau custom.");
      error.statusCode = 400;
      throw error;
    }
  }
};

const getMerchantDashboard = async (
  merchantId,
  filters = { period: "daily" }
) => {
  const createdAt = getMerchantDateRange(filters);
  const baseWhere = {
    userId: merchantId,
    type: "PAYMENT_IN",
    status: "SUCCESS",
    createdAt,
  };

  const [total, grouped, recentPayments, merchant] = await Promise.all([
    prisma.transaction.aggregate({
      where: baseWhere,
      _sum: { amount: true },
      _count: { _all: true },
    }),
    prisma.transaction.groupBy({
      by: ["subcategory"],
      where: baseWhere,
      _sum: { amount: true },
      _count: { _all: true },
    }),
    prisma.transaction.findMany({
      where: baseWhere,
      orderBy: [{ createdAt: "desc" }, { id: "desc" }],
      take: 5,
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
    }),
    prisma.user.findUnique({
      where: { id: merchantId },
      select: { merchantCategory: true },
    }),
  ]);

  const categoryNames = {
    ALLEYWAY: "Alleyway",
    PRINT: "Print",
    KANTIN: "Kantin",
    JUKEL_PO: "Jukel & PO",
    AKADEMIK: "Akademik",
  };
  const categoryCatalog = {
    KANTIN: ["Warmindo", "Kantin Teknik", "Kantin Cuweg"],
    JUKEL_PO: ["Jukel DPM", "PO BEM", "PO DPM"],
    AKADEMIK: ["BPP", "SPP"],
  };
  const groupedByName = new Map(
    grouped.map((row) => [row.subcategory || "", row])
  );
  const subcategories = categoryCatalog[merchant?.merchantCategory];
  const categories = subcategories
    ? subcategories.map((name) => {
        const row = groupedByName.get(name);
        return {
          name,
          subcategory: name,
          count: row?._count._all || 0,
          amount: row?._sum.amount || 0,
        };
      })
    : grouped.map((row) => ({
        name:
          row.subcategory ||
          categoryNames[merchant?.merchantCategory] ||
          "Umum",
        subcategory: row.subcategory,
        count: row._count._all,
        amount: row._sum.amount || 0,
      }));

  return {
    period: filters.period || "daily",
    total: {
      count: total._count._all,
      amount: total._sum.amount || 0,
    },
    categories,
    recentPayments,
  };
};

module.exports = { getMerchantDashboard, getMerchantDateRange };
