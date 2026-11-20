const express = require("express");
const router = express.Router();

const summaryController = require("./summary.controller");
const authenticate = require("../../middlewares/auth.middleware");

// Rekap pemasukan dan pengeluaran
router.get("/", authenticate, summaryController.getFinancialSummary);

module.exports = router;
