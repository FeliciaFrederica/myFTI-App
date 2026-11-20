const summaryService = require("./summary.service");

const getFinancialSummary = async (req, res, next) => {
  try {
    const period = String(req.query.period || "monthly").toLowerCase();
    const data = await summaryService.getFinancialSummary(req.user.id, period);

    return res.status(200).json({
      success: true,
      message: "Ringkasan keuangan berhasil diambil.",
      data,
    });
  } catch (error) {
    next(error);
  }
};

module.exports = { getFinancialSummary };
