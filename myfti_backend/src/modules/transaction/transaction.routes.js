const express = require("express");
const router = express.Router();

const transactionController = require("./transaction.controller");
const authenticate = require("../../middlewares/auth.middleware");

router.get("/", authenticate, transactionController.getTransactions);
router.get(
  "/incoming",
  authenticate,
  transactionController.getMerchantIncomingPayments
);
router.get("/:id", authenticate, transactionController.getTransactionDetail);

module.exports = router;