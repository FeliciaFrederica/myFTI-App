const prisma = require("../../config/prisma");
const crypto = require("crypto");

const MIN_TRANSFER = 10000;
const MAX_WALLET_BALANCE = 2147483647;

const createError = (message, statusCode) => {
  const error = new Error(message);
  error.statusCode = statusCode;
  return error;
};

// Menjalankan transaksi dengan perlindungan konflik database
const runTransferTransaction = async (callback) => {
  const maxAttempts = 3;

  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await prisma.$transaction(callback, {
        isolationLevel: "Serializable",
      });
    } catch (error) {
      // Mengulang transaksi jika terjadi konflik database
      if (error.code !== "P2034") {
        throw error;
      }

      if (attempt === maxAttempts) {
        throw createError(
          "Transaksi sedang berbenturan dengan transaksi lain. Silakan coba kembali.",
          409
        );
      }
    }
  }
};

// Mencari penerima berdasarkan Wallet ID
const getTransferRecipient = async (walletId, currentUserId) => {
  if (!walletId || typeof walletId !== "string") {
    throw createError("Wallet ID tidak valid.", 400);
  }

  if (!currentUserId) {
    throw createError("Mohon login terlebih dahulu.", 401);
  }

  const normalizedWalletId = walletId.trim();

  if (!normalizedWalletId) {
    throw createError("Wallet ID tidak valid.", 400);
  }

  const recipient = await prisma.wallet.findUnique({
    where: {
      walletId: normalizedWalletId,
    },
    select: {
      walletId: true,
      userId: true,
      user: {
        select: {
          fullName: true,
        },
      },
    },
  });

  if (!recipient) {
    throw createError("Wallet ID penerima tidak ditemukan.", 404);
  }

  if (recipient.userId === currentUserId) {
    throw createError("Tidak dapat transfer ke wallet sendiri.", 400);
  }

  return {
    walletId: recipient.walletId,
    fullName: recipient.user.fullName,
  };
};

// Memproses transfer antar mahasiswa
const transfer = async (userId, recipientWalletId, amount, description) => {
  if (!userId) {
    throw createError("Mohon login terlebih dahulu.", 401);
  }

  if (!recipientWalletId || typeof recipientWalletId !== "string") {
    throw createError("Wallet ID penerima tidak valid.", 400);
  }

  const normalizedWalletId = recipientWalletId.trim();

  if (!normalizedWalletId) {
    throw createError("Wallet ID penerima tidak valid.", 400);
  }

  // Memvalidasi nominal transfer
  if (!Number.isSafeInteger(amount) || amount < MIN_TRANSFER) {
    throw createError(
      "Minimal transfer adalah Rp10.000.",
      400
    );
  }

  if (description !== undefined && typeof description !== "string") {
    throw createError("Deskripsi transaksi tidak valid.", 400);
  }

  const normalizedDescription = description?.trim();

  return await runTransferTransaction(async (tx) => {
    // Mengambil data wallet pengirim
    const senderWallet = await tx.wallet.findUnique({
      where: {
        userId,
      },
      select: {
        walletId: true,
        balance: true,
        user: {
          select: {
            fullName: true,
          },
        },
      },
    });

    if (!senderWallet) {
      throw createError("Data wallet pengirim tidak ditemukan.", 404);
    }

    // Mengambil data wallet penerima
    const recipientWallet = await tx.wallet.findUnique({
      where: {
        walletId: normalizedWalletId,
      },
      select: {
        walletId: true,
        userId: true,
        balance: true,
        user: {
          select: {
            fullName: true,
          },
        },
      },
    });

    if (!recipientWallet) {
      throw createError("Wallet ID penerima tidak ditemukan.", 404);
    }

    // Memastikan pengirim tidak transfer ke wallet sendiri
    if (senderWallet.walletId === recipientWallet.walletId) {
      throw createError("Tidak dapat transfer ke wallet sendiri.", 400);
    }

    // Memastikan saldo pengirim mencukupi
    if (senderWallet.balance < amount) {
      throw createError("Saldo tidak mencukupi.", 400);
    }

    // Memastikan saldo penerima tidak melebihi kapasitas database
    if (recipientWallet.balance > MAX_WALLET_BALANCE - amount) {
      throw createError(
        "Saldo penerima telah mencapai batas maksimum.",
        400
      );
    }

    // Mengurangi saldo pengirim hanya jika saldo mencukupi
    const debit = await tx.wallet.updateMany({
      where: {
        walletId: senderWallet.walletId,
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
      throw createError("Saldo tidak mencukupi.", 400);
    }

    // Menambahkan saldo penerima
    await tx.wallet.update({
      where: {
        walletId: recipientWallet.walletId,
      },
      data: {
        balance: {
          increment: amount,
        },
      },
    });

    // ID untuk menghubungkan transaksi pengirim dan penerima
    const transferGroupId = crypto.randomUUID();

    // Mencatat transaksi pengirim
    const senderTransaction = await tx.transaction.create({
      data: {
        reference: `TRF-OUT-${crypto.randomUUID()}`,
        type: "TRANSFER_OUT",
        status: "SUCCESS",
        amount,
        description:
          normalizedDescription ||
          `Transfer ke ${recipientWallet.user.fullName}`,
        userId,
        transferGroupId,
        counterpartName: recipientWallet.user.fullName,
      },
    });

    // Mencatat transaksi penerima
    const recipientTransaction = await tx.transaction.create({
      data: {
        reference: `TRF-IN-${crypto.randomUUID()}`,
        type: "TRANSFER_IN",
        status: "SUCCESS",
        amount,
        description: `Transfer dari ${senderWallet.user.fullName}`,
        userId: recipientWallet.userId,
        transferGroupId,
        counterpartName: senderWallet.user.fullName,
      },
    });

    // Mengambil saldo terbaru pengirim
    const updatedWallet = await tx.wallet.findUnique({
      where: {
        userId,
      },
      select: {
        walletId: true,
        balance: true,
      },
    });

    return {
      transferGroupId,
      amount,
      wallet: updatedWallet,
      recipient: {
        walletId: recipientWallet.walletId,
        fullName: recipientWallet.user.fullName,
      },
      transactions: {
        sender: senderTransaction,
        recipient: recipientTransaction,
      },
    };
  });
};

module.exports = {
  getTransferRecipient,
  transfer,
};
