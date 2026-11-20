const crypto = require("crypto");
const { Prisma } = require("../../generated/prisma/client");
const prisma = require("../../config/prisma");

const MAX_RETRIES = 3;
const MAX_WALLET_BALANCE = 2147483647;

const getPaymentRecipients = async () => {
  const merchants = await prisma.user.findMany({
    where: {
      role: "MERCHANT",
      wallet: {
        isNot: null,
      },
    },
    select: {
      id: true,
      fullName: true,
      merchantCategory: true,
      wallet: {
        select: {
          walletId: true,
        },
      },
    },
    orderBy: {
      fullName: "asc",
    },
  });

  return merchants.map((merchant) => ({
    id: merchant.id,
    name: merchant.fullName,
    category: merchant.merchantCategory,
    walletId: merchant.wallet.walletId,
  }));
};

const createPayment = async (studentId, data) => {
  const { merchantId } = data;
  const amount = Number(data.amount);
  const description =
    typeof data.description === "string"
      ? data.description.trim()
      : "";

    if (description.length > 150) {
      throw Object.assign(
        new Error("Description must not exceed 150 characters"),
        { statusCode: 400 }
      );
    }

  // Validasi kategori pembayaran
  const allowedCategories = [
    "ALLEYWAY",
    "PRINT",
    "KANTIN",
    "JUKEL_PO",
    "AKADEMIK",
  ];

  if (!allowedCategories.includes(category)) {
    throw Object.assign(new Error("Invalid payment category"), {
      statusCode: 400,
    });
  }

  // Validasi nominal
  if (!Number.isSafeInteger(amount) || amount <= 0) {
    throw Object.assign(new Error("Invalid payment amount"), {
      statusCode: 400,
    });
  }

  for (let attempt = 1; attempt <= MAX_RETRIES; attempt++) {
    try {
      return await prisma.$transaction(
        async (tx) => {
          const student = await tx.user.findUnique({
            where: { id: studentId },
            include: { wallet: true },
          });

          const merchant = await tx.user.findFirst({
            where: {
              id: merchantId,
              role: "MERCHANT",
            },
            include: { wallet: true },
          });

          if (!merchant) {
            throw Object.assign(new Error("Merchant not found"), {
              statusCode: 404,
            });
          }
          
          if (!student || student.role !== "STUDENT") {
            throw Object.assign(new Error("Student account not found"), {
              statusCode: 404,
            });
          }

          if (!merchant || merchant.role !== "MERCHANT") {
            throw Object.assign(new Error("Merchant not found"), {
              statusCode: 404,
            });
          }

          if (!student.wallet || !merchant.wallet) {
            throw Object.assign(new Error("Wallet not found"), {
              statusCode: 404,
            });
          }

          // 1. Debit student only when the balance is sufficient.
          const debit = await tx.wallet.updateMany({
            where: {
              userId: studentId,
              balance: { gte: amount },
            },
            data: {
              balance: { decrement: amount },
            },
          });

          if (debit.count !== 1) {
            throw Object.assign(new Error("Insufficient balance"), {
              statusCode: 400,
            });
          }

          // 2. Check merchant wallet balance limit.
          const currentMerchantWallet = await tx.wallet.findUnique({
            where: { userId: merchant.id },
          });

          if (
            currentMerchantWallet.balance + amount >
            MAX_WALLET_BALANCE
          ) {
            throw Object.assign(
              new Error("Merchant wallet balance limit exceeded"),
              { statusCode: 400 }
            );
          }

          // 3. Credit merchant.
          await tx.wallet.update({
            where: { userId: merchant.id },
            data: {
              balance: { increment: amount },
            },
          });

          // 4. Create paired transaction records.
          const groupId = crypto.randomUUID();
          const reference = `PAY-${crypto.randomUUID()}`;

          await tx.transaction.createMany({
            data: [
              {
                reference,
                type: "PAYMENT",
                amount,
                description:
                  description || `Payment to ${merchant.fullName}`,
                userId: studentId,
                transferGroupId: groupId,
                counterpartName: merchant.fullName,
              },
              {
                reference: `PAY-${crypto.randomUUID()}`,
                type: "PAYMENT",
                amount,
                description:
                  description || `Payment from ${student.fullName}`,
                userId: merchant.id,
                transferGroupId: groupId,
                counterpartName: student.fullName,
              },
            ],
          });

          const updatedWallet = await tx.wallet.findUnique({
            where: { userId: studentId },
            select: { balance: true },
          });

          return {
            reference,
            amount,
            merchant: merchant.fullName,
            balance: updatedWallet.balance,
          };
        },
        {
          isolationLevel: Prisma.TransactionIsolationLevel.Serializable,
        }
      );
    } catch (error) {
      if (error.code === "P2034" && attempt < MAX_RETRIES) {
        continue;
      }

      throw error;
    }
  }
};

module.exports = {
  getPaymentRecipients,
  createPayment,
};