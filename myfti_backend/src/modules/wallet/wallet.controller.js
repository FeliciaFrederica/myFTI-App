const walletService = require("./wallet.service");

const getWallet = async (req, res) => {
  try {
    const userId = req.user?.id;

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "Mohon login terlebih dahulu.",
      });
    }

    const wallet = await walletService.getWallet(userId);

    if (!wallet) {
      return res.status(404).json({
        success: false,
        message: "Data wallet tidak ditemukan.",
      });
    }

    return res.status(200).json({
      success: true,
      message: "Data wallet berhasil diambil.",
      data: wallet,
    });
  } catch (error) {
    console.error("Get wallet error:", error);

    return res.status(500).json({
      success: false,
      message: "Gagal mengambil data wallet.",
    });
  }
};

module.exports = {
  getWallet,
};