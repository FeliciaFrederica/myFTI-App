const summaryService = require("./summary.service");
const merchantDashboardService = require("./merchant-dashboard.service");

const getMerchantDashboard = async (req, res, next) => {
  try {
    if (req.user?.role !== "MERCHANT") {
      return res.status(403).json({
        success: false,
        message: "Dashboard ini hanya tersedia untuk merchant.",
      });
    }

    const period = String(req.query.period || "daily").toLowerCase();
    const from = req.query.from ? String(req.query.from) : undefined;
    const to = req.query.to ? String(req.query.to) : undefined;
    const data = await merchantDashboardService.getMerchantDashboard(
      req.user.id,
      { period, from, to }
    );

    return res.status(200).json({
      success: true,
      message: "Dashboard merchant berhasil diambil.",
      data,
    });
  } catch (error) {
    next(error);
  }
};

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

module.exports = {
  getFinancialSummary,
  getMerchantDashboard
};
