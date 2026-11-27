const express = require("express");
const router = express.Router();

const summaryController = require("./summary.controller");
const authenticate = require("../../middlewares/auth.middleware");

router.get(
  "/merchant-dashboard",
  authenticate,
  summaryController.getMerchantDashboard
);
router.get("/", authenticate, summaryController.getFinancialSummary);

module.exports = router;