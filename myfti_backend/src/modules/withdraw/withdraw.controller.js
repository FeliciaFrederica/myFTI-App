const withdrawService = require("./withdraw.service");

// Memproses withdraw ke rekening bank simulasi
const withdraw = async (req, res) => {
  try {
    const userId = req.user?.id;

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "Mohon login terlebih dahulu.",
      });
    }

    // Memvalidasi format data request
    if (
      !req.body ||
      typeof req.body !== "object" ||
      Array.isArray(req.body)
    ) {
      return res.status(400).json({
        success: false,
        message: "Data tarik saldo tidak valid.",
      });
    }

    const result = await withdrawService.withdraw(userId, req.body);

    return res.status(200).json({
      success: true,
      message: "Tarik saldo berhasil.",
      data: result,
    });
  } catch (error) {
    console.error("Withdraw error:", error);

    return res.status(error.statusCode || 500).json({
      success: false,
      message: error.statusCode
        ? error.message
        : "Gagal melakukan tarik saldo.",
    });
  }
};

// Mengambil daftar rekening bank yang tersimpan
const getSavedBankAccounts = async (req, res) => {
  try {
    const userId = req.user?.id;

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "Mohon login terlebih dahulu.",
      });
    }

    const accounts = await withdrawService.getSavedBankAccounts(userId);

    return res.status(200).json({
      success: true,
      message: "Daftar rekening berhasil diambil.",
      data: accounts,
    });
  } catch (error) {
    console.error("Get saved bank accounts error:", error);

    return res.status(error.statusCode || 500).json({
      success: false,
      message: error.statusCode
        ? error.message
        : "Gagal mengambil daftar rekening.",
    });
  }
};

module.exports = {
  withdraw,
  getSavedBankAccounts,
};