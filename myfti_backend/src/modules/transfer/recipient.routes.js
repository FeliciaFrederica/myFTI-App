const express = require("express");
const router = express.Router();

const transferController = require("./transfer.controller");
const authenticate = require("../../middleware/auth.middleware");

// Mencari penerima berdasarkan Wallet ID
router.get("/:walletId", authenticate, transferController.getTransferRecipient);

module.exports = router;
