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

    if (
      !req.body ||
      typeof req.body !== "object" ||
      Array.isArray(req.body)
    ) {
      return res.status(400).json({
        success: false,
        message: "Data withdraw tidak valid.",
      });
    }

    const result = await withdrawService.withdraw(
      userId,
      req.body
    );

    return res.status(200).json({
      success: true,
      message: "Withdraw berhasil.",
      data: result,
    });
  } catch (error) {
    console.error("Withdraw error:", error);

    return res.status(error.statusCode || 500).json({
      success: false,
      message:
        error.statusCode
          ? error.message
          : "Gagal melakukan withdraw.",
    });
  }
};

module.exports = {
  withdraw,
};
