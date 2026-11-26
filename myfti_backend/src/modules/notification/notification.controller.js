const notificationService = require("./notification.service");

const listNotifications = async (req, res, next) => {
  try {
    const unreadOnly = String(req.query.unread || "") === "true";
    const data = await notificationService.listNotifications(req.user.id, {
      unreadOnly,
      limit: req.query.limit,
    });

    return res.status(200).json({
      success: true,
      message: "Daftar notifikasi berhasil diambil.",
      data,
    });
  } catch (error) {
    next(error);
  }
};

const markAsRead = async (req, res, next) => {
  try {
    const data = await notificationService.markAsRead(
      req.user.id,
      req.params.id
    );

    return res.status(200).json({
      success: true,
      message: "Notifikasi ditandai sudah dibaca.",
      data,
    });
  } catch (error) {
    next(error);
  }
};

const deleteNotification = async (req, res, next) => {
  try {
    const data = await notificationService.deleteNotification(
      req.user.id,
      req.params.id
    );

    return res.status(200).json({
      success: true,
      message: "Notifikasi berhasil dihapus.",
      data,
    });
  } catch (error) {
    next(error);
  }
};

const deleteAllNotifications = async (req, res, next) => {
  try {
    const data = await notificationService.deleteAllNotifications(req.user.id);

    return res.status(200).json({
      success: true,
      message: "Semua notifikasi berhasil dihapus.",
      data,
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  listNotifications,
  markAsRead,
  deleteNotification,
  deleteAllNotifications,
};
