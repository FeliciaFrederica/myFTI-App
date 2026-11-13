const express = require("express");
const cors = require("cors");
const helmet = require("helmet");

const walletRoutes = require("./modules/wallet/wallet.routes");
const authRoutes = require("./routes/auth.routes");
const authMiddleware = require("./middlewares/auth.middleware");
const errorHandler = require("./middlewares/error.middleware");

const app = express();

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

// log request
app.use((req, res, next) => {
  console.log(`${req.method} ${req.originalUrl}`);
  next();
});
app.use(express.json());

app.get("/api", (req, res) => {
  res.json({ success: true, message: "Welcome to myFTI API!" });
});
app.get("/api/health", (req, res) =>
  res.json({ success: true, message: "myFTI API hidup" })
);

app.use("/api/auth", authRoutes);
// wallet dilindungi token; hapus authMiddleware di sini jika
// wallet.routes.js sudah memasangnya sendiri
app.use("/api/wallet", authMiddleware, walletRoutes);

// 404 untuk endpoint yang tidak ada
app.use((req, res) => {
  console.log("404 ->", req.method, req.originalUrl);
  res.status(404).json({
    success: false,
    message: `Endpoint tidak ditemukan: ${req.method} ${req.originalUrl}`,
  });
});

app.use(errorHandler);
app.use("/api/wallet", walletRoutes);

module.exports = app;