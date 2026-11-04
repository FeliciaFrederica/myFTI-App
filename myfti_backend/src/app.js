const express = require("express");
const walletRoutes = require("./modules/wallet/wallet.routes");

const app = express();

app.use(express.json());

app.get("/api", (req, res) => {
  res.json({
    message: "Welcome to myFTI API!",
  });
});

app.use("/api/wallet", walletRoutes);

module.exports = app;