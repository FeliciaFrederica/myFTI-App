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

const topUp = async (req, res) => {
  try {
    const userId = req.user?.id;
    const { amount } = req.body;

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "Mohon login terlebih dahulu.",
      });
    }

    if (!Number.isInteger(amount) || amount < 10000) {
      return res.status(400).json({
        success: false,
        message: "Minimal Top Up adalah Rp 10.000.",
      });
    }

    const result = await walletService.topUp(userId, amount);

    if (!result) {
      return res.status(404).json({
        success: false,
        message: "Data wallet tidak ditemukan.",
      });
    }

    return res.status(200).json({
      success: true,
      message: "Top up berhasil.",
      data: result,
    });
  } catch (error) {
    console.error("Top up error:", error);

    return res.status(500).json({
      success: false,
      message: "Gagal melakukan top up.",
    });
  }
};

module.exports = {
  getWallet,
  topUp,
};