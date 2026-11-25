const express = require("express");
const router = express.Router();

const notificationController = require("./notification.controller");
const authenticate = require("../../middlewares/auth.middleware");

// Daftar notifikasi milik user
router.get("/", authenticate, notificationController.listNotifications);

// Tandai satu notifikasi sudah dibaca
router.put("/:id/read", authenticate, notificationController.markAsRead);

module.exports = router;
