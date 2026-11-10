const express = require("express");

const walletRoutes = require("./modules/wallet/wallet.routes");
const transferRoutes = require("./modules/transfer/transfer.routes");
const withdrawRoutes = require("./modules/withdraw/withdraw.routes");

const app = express();

// Middleware untuk membaca JSON request
app.use(express.json());

// Welcome API
app.get("/api", (req, res) => {
  res.json({
    message: "Welcome to myFTI API!",
  });
});

// Wallet
app.use("/api/wallet", walletRoutes);

// Transfer
app.use("/api/transfers", transferRoutes);

// Withdraw
app.use("/api/withdrawals", withdrawRoutes);

module.exports = app;
