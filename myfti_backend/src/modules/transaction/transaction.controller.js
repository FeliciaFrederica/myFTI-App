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

    const parsedLimit = Number.parseInt(req.query.limit, 10);
    const limit = Number.isNaN(parsedLimit) ? 10 : parsedLimit;

    if (limit < 1 || limit > 50) {
      return res.status(400).json({
        success: false,
        message: "Limit harus antara 1 sampai 50.",
      });
    }

    const cursor = req.query.cursor || null;
    const sort = req.query.sort || "desc";

    if (sort !== "asc" && sort !== "desc") {
      return res.status(400).json({
        success: false,
        message: "Parameter sort tidak valid.",
      });
    }

    const result = await transactionService.getTransactions(userId, {
      limit,
      cursor,
      sort,
    });

    return res.status(200).json({
      success: true,
      message: "Riwayat transaksi berhasil diambil.",
      data: result.transactions,
      pagination: result.pagination,
    });
  } catch (error) {
    console.error("Get transactions error:", error);

    return res.status(error.statusCode || 500).json({
      success: false,
      message:
        error.statusCode === 400
          ? error.message
          : "Gagal mengambil riwayat transaksi.",
    });
  }
};

module.exports = { getTransactions };