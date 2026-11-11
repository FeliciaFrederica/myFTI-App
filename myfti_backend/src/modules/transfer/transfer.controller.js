const transferService = require("./transfer.service");

// Mencari penerima berdasarkan Wallet ID
const getTransferRecipient = async (req, res) => {
  try {
    const userId = req.user?.id;
    const { walletId } = req.params;

    const recipient = await transferService.getTransferRecipient(
      walletId,
      userId
    );

    return res.status(200).json({
      success: true,
      message: "Data penerima berhasil ditemukan.",
      data: recipient,
    });
  } catch (error) {
    console.error("Get transfer recipient error:", error);

    return res.status(error.statusCode || 500).json({
      success: false,
      message: error.statusCode
        ? error.message
        : "Gagal mencari data penerima.",
    });
  }
};

// Memproses transfer antar mahasiswa
const transfer = async (req, res) => {
  try {
    const userId = req.user?.id;

    // Memvalidasi format data request
    if (
      !req.body ||
      typeof req.body !== "object" ||
      Array.isArray(req.body)
    ) {
      return res.status(400).json({
        success: false,
        message: "Data transfer tidak valid.",
      });
    }

    const { recipientWalletId, amount, description } = req.body;

    const result = await transferService.transfer(
      userId,
      recipientWalletId,
      amount,
      description
    );

    return res.status(200).json({
      success: true,
      message: "Transfer berhasil.",
      data: result,
    });
  } catch (error) {
    console.error("Transfer error:", error);

    return res.status(error.statusCode || 500).json({
      success: false,
      message: error.statusCode
        ? error.message
        : "Gagal melakukan transfer.",
    });
  }
};

module.exports = {
  getTransferRecipient,
  transfer,
};