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

module.exports = { getTransactions };