const express = require("express");
const router = express.Router();

const transferController = require("./transfer.controller");
const authenticate = require("../../middleware/auth.middleware");

// Mencari penerima berdasarkan Wallet ID
// Endpoint: GET /api/users/recipient/:walletId
// Route ini nantinya didaftarkan pada users router.

// Melakukan transfer antar mahasiswa
// Endpoint: POST /api/transfers
router.post("/", authenticate, transferController.transfer);

module.exports = router;
