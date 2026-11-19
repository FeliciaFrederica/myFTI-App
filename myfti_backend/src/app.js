const express = require("express");
const cors = require("cors");
const helmet = require("helmet");

const authRoutes = require("./routes/auth.routes");
const transactionRoutes = require("./modules/transaction/transaction.routes");
const paymentRoutes = require("./modules/payment/payment.routes");
const errorHandler = require("./middlewares/error.middleware");
const walletRoutes = require("./modules/wallet/wallet.routes");
const transferRoutes = require("./modules/transfer/transfer.routes");
const withdrawRoutes = require("./modules/withdraw/withdraw.routes");
const recipientRoutes = require("./modules/transfer/recipient.routes");

const app = express();

// Security
app.use(
  helmet({
    crossOriginResourcePolicy: { policy: "cross-origin" },
  })
);

app.use(
  cors({
    origin: true,
    methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization"],
  })
);

app.use(express.json({ limit: "1mb" }));

// Log request
app.use((req, res, next) => {
  console.log(`${req.method} ${req.originalUrl}`);
  next();
});

// Welcome API
app.get("/api", (req, res) => {
  res.json({
    success: true,
    message: "Welcome to myFTI API!",
  });
});

// Health check
app.get("/api/health", (req, res) => {
  res.json({
    success: true,
    message: "myFTI API hidup",
  });
});

// Authentication
app.use("/api/auth", authRoutes);

// Transaction
app.use("/api/transactions", transactionRoutes);

// Payment
app.use("/api/payments", paymentRoutes);

// Wallet
app.use("/api/wallet", walletRoutes);

// Transfer
app.use("/api/transfers", transferRoutes);

// Withdraw
app.use("/api/withdrawals", withdrawRoutes);

// Transfer recipient
app.use("/api/users/recipient", recipientRoutes);

// Endpoint tidak ditemukan
app.use((req, res) => {
  console.log("404 ->", req.method, req.originalUrl);

  res.status(404).json({
    success: false,
    message: `Endpoint tidak ditemukan: ${req.method} ${req.originalUrl}`,
  });
});

// Global error handler
app.use(errorHandler);
// app.use("/api/wallet", walletRoutes);

module.exports = app;