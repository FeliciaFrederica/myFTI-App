const express = require("express");
const router = express.Router();

const withdrawController = require("./withdraw.controller");
const authenticate = require("../../middleware/auth.middleware");

// Mengambil daftar rekening bank tersimpan
router.get(
  "/bank-accounts",
  authenticate,
  withdrawController.getSavedBankAccounts
);

// Melakukan withdraw ke rekening bank simulasi
router.post("/", authenticate, withdrawController.withdraw);

module.exports = router;
