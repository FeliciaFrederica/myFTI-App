const paymentService = require("./payment.service");

const getRecipients = async (req, res, next) => {
  try {
    const recipients = await paymentService.getPaymentRecipients();

    res.status(200).json({
      success: true,
      data: recipients,
    });
  } catch (error) {
    next(error);
  }
};

const createPayment = async (req, res, next) => {
  try {
    const result = await paymentService.createPayment(
      req.user.id,
      req.body
    );

    res.status(200).json({
      success: true,
      message: "Payment successful",
      data: result,
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getRecipients,
  createPayment,
};