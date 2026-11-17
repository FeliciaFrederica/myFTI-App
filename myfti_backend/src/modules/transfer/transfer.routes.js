const express = require("express");
const router = express.Router();

const transferController = require("./transfer.controller");
const authenticate = require("../../middlewares/auth.middleware");

// Melakukan transfer antar mahasiswa
router.post("/", authenticate, transferController.transfer);

module.exports = router;