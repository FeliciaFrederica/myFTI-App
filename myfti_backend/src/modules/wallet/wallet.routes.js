const express = require("express");
const router = express.Router();

const walletController = require("./wallet.controller");
const authenticate = require("../../middlewares/auth.middleware");

router.get("/", authenticate, walletController.getWallet);
router.post("/top-up", authenticate, walletController.topUp);

module.exports = router;