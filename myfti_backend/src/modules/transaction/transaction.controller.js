const transactionService = require("./transaction.service");

const getTransactions = async (req, res) => {
  try {
    const userId = req.user?.id;

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "Mohon login terlebih dahulu.",
      });
    }

    const transactions =
      await transactionService.getTransactions(userId);

    return res.status(200).json({
      success: true,
      message: "Riwayat transaksi berhasil diambil.",
      data: transactions,
    });
  } catch (error) {
    console.error("Get transactions error:", error);

    return res.status(500).json({
      success: false,
      message: "Gagal mengambil riwayat transaksi.",
    });
  }
};

const getTransactionDetail = async (req, res) => {
  try {
    const userId = req.user?.id;
    const transactionId = req.params.id?.trim();

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "Mohon login terlebih dahulu.",
      });
    }

    if (!transactionId) {
      return res.status(400).json({
        success: false,
        message: "ID transaksi tidak valid.",
      });
    }

    const transaction = await transactionService.getTransactionDetail(
      userId,
      transactionId
    );

    if (!transaction) {
      return res.status(404).json({
        success: false,
        message: "Transaksi tidak ditemukan.",
      });
    }

    return res.status(200).json({
      success: true,
      message: "Detail transaksi berhasil diambil.",
      data: transaction,
    });
  } catch (error) {
    console.error("Get transaction detail error:", error);

    return res.status(500).json({
      success: false,
      message: "Gagal mengambil detail transaksi.",
    });
  }
};

module.exports = { getTransactions, getTransactionDetail };