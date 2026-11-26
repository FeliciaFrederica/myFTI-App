const prisma = require("../../config/prisma");

const createError = (message, statusCode) => {
  const error = new Error(message);
  error.statusCode = statusCode;
  return error;
};

const SELECT_FIELDS = {
  id: true,
  title: true,
  message: true,
  isRead: true,
  createdAt: true,
};

const listNotifications = async (userId, { unreadOnly = false, limit = 50 } = {}) => {
  if (!userId) {
    throw createError("Mohon login terlebih dahulu.", 401);
  }

  const take = Math.min(Math.max(Number(limit) || 50, 1), 100);

  return prisma.notification.findMany({
    where: {
      userId,
      ...(unreadOnly ? { isRead: false } : {}),
    },
    orderBy: { createdAt: "desc" },
    take,
    select: SELECT_FIELDS,
  });
};

const markAsRead = async (userId, notificationId) => {
  if (!userId) {
    throw createError("Mohon login terlebih dahulu.", 401);
  }

  if (!notificationId || typeof notificationId !== "string") {
    throw createError("ID notifikasi tidak valid.", 400);
  }

  const result = await prisma.notification.updateMany({
    where: { id: notificationId, userId },
    data: { isRead: true },
  });

  if (result.count === 0) {
    throw createError("Notifikasi tidak ditemukan.", 404);
  }

  return prisma.notification.findUnique({
    where: { id: notificationId },
    select: SELECT_FIELDS,
  });
};

const markAllAsRead = async (userId) => {
  if (!userId) {
    throw createError("Mohon login terlebih dahulu.", 401);
  }

  const result = await prisma.notification.updateMany({
    where: { userId, isRead: false },
    data: { isRead: true },
  });

  return { updatedCount: result.count };
};

const deleteNotification = async (userId, notificationId) => {
  if (!userId) {
    throw createError("Mohon login terlebih dahulu.", 401);
  }

  if (!notificationId || typeof notificationId !== "string") {
    throw createError("ID notifikasi tidak valid.", 400);
  }

  const result = await prisma.notification.deleteMany({
    where: { id: notificationId, userId },
  });

  if (result.count === 0) {
    throw createError("Notifikasi tidak ditemukan.", 404);
  }

  return { id: notificationId };
};

const deleteAllNotifications = async (userId) => {
  if (!userId) {
    throw createError("Mohon login terlebih dahulu.", 401);
  }

  const result = await prisma.notification.deleteMany({
    where: { userId },
  });

  return { deletedCount: result.count };
};

module.exports = {
  listNotifications,
  markAsRead,
  markAllAsRead,
  deleteNotification,
  deleteAllNotifications,
};
