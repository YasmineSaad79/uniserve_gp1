//  routes/studentRequests.js
const express = require('express');
const router = express.Router();

const verifyToken = require('../middleware/verifyToken');
const authorizePermission = require('../middleware/authorizePermission');
const controller = require('../controllers/studentRequestsController');

// ======================================================
//  كل المسارات محمية
// ======================================================
router.use(verifyToken);

// ======================================================
//  إرسال اقتراح جديد + إشعار للمركز
//  Permission: canSendMessages
// ======================================================
router.post(
  '/',
  authorizePermission('canSendMessages'),
  controller.createRequest
);

// ======================================================
//  جلب طلبات طالب معيّن
//  Permission: canViewProfile
// ======================================================
router.get(
  '/:studentId',
  authorizePermission('canViewProfile'),
  controller.getRequestsByStudent
);

// ======================================================
//  تحديث حالة الطلب (قبول / رفض) + إشعار للطالب
//  Permission: canUpdateCustomRequests
// ======================================================
router.patch(
  '/:id/status',
  authorizePermission('canUpdateCustomRequests'),
  controller.updateRequestStatus
);

module.exports = router;
