const prisma = require("../../config/prisma");
const { getMerchantDateRange } = require("./merchant-dashboard.service");
const { notify, formatRupiah } = require("../../utils/notify");

const WIB_OFFSET_MS = 7 * 60 * 60 * 1000;
const DAY_MS = 24 * 60 * 60 * 1000;
let scheduler;
let running = false;

const getWibParts = (date) => {
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone: "Asia/Jakarta",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    hourCycle: "h23",
  }).formatToParts(date);
  return Object.fromEntries(parts.map(({ type, value }) => [type, value]));
};

const settlePreviousDay = async (now = new Date()) => {
  const local = getWibParts(now);
  if (Number(local.hour) < 6) return;

  const today = getMerchantDateRange({ period: "daily" }, now);
  const yesterday = {
    gte: new Date(today.gte.getTime() - DAY_MS),
    lt: today.gte,
  };
  const dateKey = new Intl.DateTimeFormat("en-CA", {
    timeZone: "Asia/Jakarta",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(new Date(yesterday.gte.getTime() + WIB_OFFSET_MS));

  const merchants = await prisma.user.findMany({
    where: { role: "MERCHANT" },
    select: { id: true },
  });

  for (const merchant of merchants) {
    const reference = `AUTO-PAYOUT-${merchant.id}-${dateKey}`;
    try {
      await prisma.$transaction(
        async (tx) => {
          const existing = await tx.transaction.findUnique({
            where: { reference },
            select: { id: true },
          });
          if (existing) return;

          // Rekening tersimpan terbaru menjadi rekening payout merchant.
          const account = await tx.bankAccount.findFirst({
            where: { userId: merchant.id },
            orderBy: { updatedAt: "desc" },
            select: { bankCode: true, accountNumber: true },
          });
          if (!account) {
            console.warn(`Payout ${merchant.id} dilewati: rekening merchant belum tersedia.`);
            return;
          }

          const income = await tx.transaction.aggregate({
            where: {
              userId: merchant.id,
              type: "PAYMENT_IN",
              status: "SUCCESS",
              createdAt: yesterday,
            },
            _sum: { amount: true },
          });
          const amount = income._sum.amount || 0;
          if (amount <= 0) return;

          const wallet = await tx.wallet.findUnique({
            where: { userId: merchant.id },
            select: { balance: true },
          });
          if (!wallet || wallet.balance < amount) {
            console.warn(`Payout ${merchant.id} dilewati: saldo wallet kurang dari pemasukan kemarin.`);
            return;
          }

          const debit = await tx.wallet.updateMany({
            where: { userId: merchant.id, balance: { gte: amount } },
            data: { balance: { decrement: amount } },
          });
          if (debit.count !== 1) return;

          await tx.transaction.create({
            data: {
              reference,
              type: "WITHDRAW",
              status: "SUCCESS",
              amount,
              description: `Pencairan otomatis untuk pemasukan ${dateKey}`,
              userId: merchant.id,
              counterpartName: account.bankCode,
              bankCode: account.bankCode,
              accountNumber: account.accountNumber,
            },
          });

          await notify(
            tx,
            merchant.id,
            "Pencairan otomatis berhasil",
            `Pemasukan ${dateKey} sebesar ${formatRupiah(amount)} sudah dicairkan ke rekening tersimpan.`
          );
        },
        { isolationLevel: "Serializable" }
      );
    } catch (error) {
      if (error.code === "P2002") continue;
      console.error(`Payout otomatis gagal untuk merchant ${merchant.id}:`, error);
    }
  }
};

const startMerchantPayoutScheduler = () => {
  if (scheduler) return;
  const run = async () => {
    if (running) return;
    running = true;
    try {
      await settlePreviousDay();
    } catch (error) {
      console.error("Payout merchant otomatis gagal:", error);
    } finally {
      running = false;
    }
  };

  void run();
  // Polling ringan menangkap jam 06.00 WIB dan mencoba ulang jika database
  // sempat tidak tersedia. Referensi unik mencegah payout ganda.
  scheduler = setInterval(run, 60 * 1000);
};

const stopMerchantPayoutScheduler = () => {
  if (scheduler) clearInterval(scheduler);
  scheduler = null;
};

module.exports = {
  startMerchantPayoutScheduler,
  stopMerchantPayoutScheduler,
  settlePreviousDay,
};
