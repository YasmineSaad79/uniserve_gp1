// routes/notifications.js
const express = require('express');
const router = express.Router();
const verifyToken = require('../middleware/verifyToken');
const controller = require('../controllers/notificationsController');

// كل مسارات الإشعارات محمية
router.use(verifyToken);

// حفظ/تحديث توكن جهاز للمستخدم الحالي
router.post('/register-token', controller.registerDeviceToken);

// الطالب يطلب التطوع (ينشئ طلب + يرسل إشعار لمركز الخدمة)
router.post('/volunteer-request', controller.createVolunteerRequest);

// قائمة إشعاراتي (للطرفين)
router.get('/my', controller.listMyNotifications);

// عدّاد غير المقروء
router.get('/unread-count', controller.unreadCount);

// علِّم كمقروء
router.patch('/:id/read', controller.markAsRead);

// مركز الخدمة يتخذ إجراء (قبول/رفض) ➜ تحديث الطلب + إنشاء إشعار للطالب
router.post('/:id/act', controller.actOnNotification);

module.exports = router;
