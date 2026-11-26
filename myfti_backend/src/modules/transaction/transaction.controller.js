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

const getMerchantIncomingPayments = async (req, res) => {
  try {
    if (req.user?.role !== "MERCHANT") {
      return res.status(403).json({
        success: false,
        message: "Riwayat ini hanya tersedia untuk merchant.",
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

    const result = await transactionService.getMerchantIncomingPayments(
      req.user.id,
      {
        limit,
        cursor: req.query.cursor || null,
        period: String(req.query.period || "daily").toLowerCase(),
        from: req.query.from ? String(req.query.from) : undefined,
        to: req.query.to ? String(req.query.to) : undefined,
        subcategory: req.query.subcategory
          ? String(req.query.subcategory)
          : undefined,
      }
    );

    return res.status(200).json({
      success: true,
      message: "Riwayat pembayaran masuk berhasil diambil.",
      data: result.transactions,
      pagination: result.pagination,
    });
  } catch (error) {
    console.error("Get merchant incoming payments error:", error);

    return res.status(error.statusCode || 500).json({
      success: false,
      message: error.statusCode
        ? error.message
        : "Gagal mengambil riwayat pembayaran masuk.",
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
      message: "Transaksi berhasil diambil.",
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

module.exports = {
  getTransactions,
  getMerchantIncomingPayments,
  getTransactionDetail,
};
