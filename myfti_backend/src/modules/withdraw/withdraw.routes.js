const express = require("express");
const router = express.Router();

const withdrawController = require("./withdraw.controller");
const authenticate = require("../../middleware/auth.middleware");

// Melakukan withdraw ke rekening bank simulasi
// Endpoint: POST /api/withdrawals
router.post("/", authenticate, withdrawController.withdraw);

module.exports = router;
