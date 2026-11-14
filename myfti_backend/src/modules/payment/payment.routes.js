const express = require("express");
const router = express.Router();

const paymentController = require("./payment.controller");
const authenticate = require("../../middlewares/auth.middleware");

router.get("/recipients", authenticate, paymentController.getRecipients);
router.post("/", authenticate, paymentController.createPayment);

module.exports = router;