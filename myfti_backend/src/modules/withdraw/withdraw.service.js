const prisma = require("../../config/prisma");
const crypto = require("crypto");

const MIN_WITHDRAW = 10000;

// Daftar bank simulasi yang tersedia
const BANKS = {
  ABC: "ABC",
  MANDIRIW: "Mandiriw",
  BNN: "BNN",
};

const createError = (message, statusCode) => {
  const error = new Error(message);
  error.statusCode = statusCode;
  return error;
};

// Memvalidasi bank tujuan
const validateBank = (bankCode) => {
  if (typeof bankCode !== "string") {
    throw createError("Bank tujuan tidak valid.", 400);
  }

  const normalizedCode = bankCode.trim().toUpperCase();
  const bankName = BANKS[normalizedCode];

  if (!bankName) {
    throw createError("Bank tujuan tidak tersedia.", 400);
  }

  return {
    bankCode: normalizedCode,
    bankName,
  };
};

// Memproses withdraw
const withdraw = async (
  userId,
  {
    bankAccountId,
    bankCode,
    accountNumber,
    amount,
    saveAccount = false,
  }
) => {
  if (!userId) {
    throw createError("Mohon login terlebih dahulu.", 401);
  }

  // Validasi nominal withdraw
  if (!Number.isInteger(amount) || amount < MIN_WITHDRAW) {
    throw createError(
      "Minimal withdraw adalah Rp 10.000.",
      400
    );
  }

  // Menentukan rekening tujuan
  let destination;

  if (bankAccountId) {
    if (
      typeof bankAccountId !== "string" ||
      bankCode !== undefined ||
      accountNumber !== undefined ||
      saveAccount !== false
    ) {
      throw createError("Data rekening tujuan tidak valid.", 400);
    }

    destination = {
      bankAccountId: bankAccountId.trim(),
    };
  } else {
    const bank = validateBank(bankCode);

    // Validasi nomor rekening
    if (
      typeof accountNumber !== "string" ||
      !/^\d{10,16}$/.test(accountNumber)
    ) {
      throw createError(
        "Nomor rekening harus berupa 10–16 digit angka.",
        400
      );
    }

    if (typeof saveAccount !== "boolean") {
      throw createError("Pilihan simpan rekening tidak valid.", 400);
    }

    destination = {
      bankCode: bank.bankCode,
      bankName: bank.bankName,
      accountNumber,
    };
  }

  return await prisma.$transaction(async (tx) => {
    // Memeriksa wallet pengguna
    const wallet = await tx.wallet.findUnique({
      where: { userId },
      select: {
        walletId: true,
        balance: true,
      },
    });

    if (!wallet) {
      throw createError("Data wallet tidak ditemukan.", 404);
    }

    // Memastikan saldo mencukupi
    if (wallet.balance < amount) {
      throw createError("Saldo tidak mencukupi.", 400);
    }

    let targetBank;
    let targetAccountNumber;

    // Mengambil rekening yang sudah tersimpan
    if (destination.bankAccountId) {
      const savedAccount = await tx.bankAccount.findFirst({
        where: {
          id: destination.bankAccountId,
          userId,
        },
      });

      if (!savedAccount) {
        throw createError(
          "Rekening tersimpan tidak ditemukan.",
          404
        );
      }

      targetBank = validateBank(savedAccount.bankCode);
      targetAccountNumber = savedAccount.accountNumber;
    } else {
      targetBank = {
        bankCode: destination.bankCode,
        bankName: destination.bankName,
      };

      targetAccountNumber = destination.accountNumber;

      // Menyimpan rekening baru jika pengguna memilihnya
      if (saveAccount) {
        await tx.bankAccount.upsert({
          where: {
            userId_bankCode_accountNumber: {
              userId,
              bankCode: targetBank.bankCode,
              accountNumber: targetAccountNumber,
            },
          },
          update: {},
          create: {
            userId,
            bankCode: targetBank.bankCode,
            accountNumber: targetAccountNumber,
          },
        });
      }
    }

    // Mengurangi saldo hanya jika masih mencukupi
    const debit = await tx.wallet.updateMany({
      where: {
        userId,
        balance: {
          gte: amount,
        },
      },
      data: {
        balance: {
          decrement: amount,
        },
      },
    });

    if (debit.count !== 1) {
      throw createError(
        "Saldo tidak mencukupi atau telah berubah. Silakan coba kembali.",
        409
      );
    }

    // Mencatat transaksi withdraw
    const transaction = await tx.transaction.create({
      data: {
        reference: `WDR-${crypto.randomUUID()}`,
        type: "WITHDRAW",
        status: "SUCCESS",
        amount,
        description: `Withdraw ke Bank ${targetBank.bankName}`,
        userId,
        counterpartName: targetBank.bankName,
        bankCode: targetBank.bankCode,
        accountNumber: targetAccountNumber,
      },
    });

    // Mengambil saldo terbaru
    const updatedWallet = await tx.wallet.findUnique({
      where: { userId },
      select: {
        walletId: true,
        balance: true,
      },
    });

    return {
      wallet: updatedWallet,
      destination: {
        bankCode: targetBank.bankCode,
        bankName: targetBank.bankName,
        accountNumber: targetAccountNumber,
      },
      transaction,
    };
  });
};


// Mengambil daftar rekening bank yang tersimpan
const getSavedBankAccounts = async (userId) => {
  if (!userId) {
    throw createError("Mohon login terlebih dahulu.", 401);
  }

  const accounts = await prisma.bankAccount.findMany({
    where: {
      userId,
    },
    orderBy: {
      createdAt: "desc",
    },
    select: {
      id: true,
      bankCode: true,
      accountNumber: true,
      createdAt: true,
    },
  });

  return accounts;
};

module.exports = {
  withdraw,
  getSavedBankAccounts,
};
