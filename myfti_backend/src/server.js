require("dotenv").config();

// Cek konfigurasi wajib sebelum server menyala
if (!process.env.JWT_SECRET || process.env.JWT_SECRET.length < 32) {
  console.error("JWT_SECRET belum diset / terlalu pendek (min 32 karakter) di .env");
  process.exit(1);
}
if (!process.env.DATABASE_URL) {
  console.error("DATABASE_URL belum diset di .env");
  process.exit(1);
}

const app = require("./app");
const prisma = require("./config/prisma");

const PORT = process.env.PORT || 3000;

const server = app.listen(PORT, "0.0.0.0", () => {
  console.log(`myFTI API jalan di port ${PORT}`);
});

server.on("error", (err) => {
  if (err.code === "EADDRINUSE") {
    console.error(
      `Port ${PORT} sudah dipakai proses lain. Matikan dulu proses lama ` +
        `(cek: netstat -ano | findstr :${PORT}, lalu taskkill /PID <PID> /F).`
    );
  } else {
    console.error("Server error:", err);
  }
  process.exit(1);
});

// Tutup koneksi database dengan rapi saat server dimatikan
const shutdown = async () => {
  server.close();
  await prisma.$disconnect();
  process.exit(0);
};
process.on("SIGINT", shutdown);
process.on("SIGTERM", shutdown);

process.on("unhandledRejection", (reason) => {
  console.error("Unhandled rejection:", reason);
});