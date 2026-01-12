//  routes/notifications.js
const express = require('express');
const router = express.Router();



const verifyToken = require('../middleware/verifyToken');
const authorizePermission = require('../middleware/authorizePermission');
const controller = require('../controllers/notificationsController');

// ======================================================
//  كل مسارات الإشعارات محمية (Authentication)
// ======================================================
router.use(verifyToken);

// ======================================================
//  حفظ / تحديث Device Token للمستخدم
//  Permission: canSendMessages
// ======================================================
router.post(
  '/register-token',
  authorizePermission('canSendMessages'),
  controller.registerDeviceToken
);

// ======================================================
//  الطالب يطلب التطوع
// (إنشاء طلب + إرسال إشعار لمركز الخدمة)
//  Permission: canSendMessages
// ======================================================
router.post(
  '/volunteer-request',
  authorizePermission('canSendMessages'),
  controller.createVolunteerRequest
);

// ======================================================
//  قائمة إشعاراتي
//  Permission: canViewMessages
// ======================================================
router.get(
  '/my',
  authorizePermission('canViewMessages'),
  controller.listMyNotifications
);

// ======================================================
//  عدّاد الإشعارات غير المقروءة
//  Permission: canViewMessages
// ======================================================
router.get(
  '/unread-count',
  authorizePermission('canViewMessages'),
  controller.unreadCount
);

// ======================================================
//  تعليم إشعار كمقروء
//  Permission: canViewMessages
// ======================================================
router.patch(
  '/:id/read',
  authorizePermission('canViewMessages'),
  controller.markAsRead
);

// ======================================================
//  مركز الخدمة يتخذ إجراء (قبول / رفض)
//  تحديث الطلب + إشعار الطالب
//  Permission: canProcessHours
// ======================================================
router.post(
  '/:id/act',
  authorizePermission('canProcessHours'),
  controller.actOnNotification
);

module.exports = router;
