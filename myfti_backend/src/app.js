const express = require("express");
const cors = require("cors");
const walletRoutes = require("./modules/wallet/wallet.routes");

const app = express();

app.use(cors());
app.use(express.json());

app.get("/api", (req, res) => {
  res.json({
    message: "Welcome to myFTI API!",
  });
});

app.use("/api/wallet", walletRoutes);
app.use("/api", require("./routes/auth.routes"));

module.exports = app;