const summaryService = require("./summary.service");

const getFinancialSummary = async (req, res, next) => {
  try {
    const period = String(req.query.period || "monthly").toLowerCase();
    const from = req.query.from ? String(req.query.from) : undefined;
    const to = req.query.to ? String(req.query.to) : undefined;

    const data = await summaryService.getFinancialSummary(req.user.id, period, {
      from,
      to,
    });

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
