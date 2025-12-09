// 📁 routes/activityRoutes.js
const express = require('express');
const router = express.Router();

const activityController = require('../controllers/activityController');
const upload = require('../middleware/upload');
const verifyToken = require('../middleware/verifyToken');
const authorizePermission = require('../middleware/authorizePermission');

// 🧾 لوج لأي طلب يتم على الراوت
const logRequest = (req, res, next) => {
  console.log(`🟢 [${req.method}] Request to /api/activities${req.path}`);
  next();
};

// ======================================================
// 🟣 إضافة نشاط جديد (صلاحية: canAddActivity)
// ======================================================
router.post(
  '/',
  verifyToken,
  authorizePermission('canAddActivity'),
  logRequest,
  upload.fields([
    { name: 'image', maxCount: 1 },
    { name: 'form', maxCount: 1 },
  ]),
  (req, res) => {
    try {
      activityController.addActivity(req, res);
    } catch (err) {
      console.error("❌ Upload or Controller Error:", err);
      res.status(400).json({ success: false, message: err.message });
    }
  }
);

// ======================================================
// 🔵 جلب كل الأنشطة (صلاحية: canViewActivities)
// ======================================================
router.get(
  '/',
  verifyToken,
  authorizePermission('canViewActivities'),
  logRequest,
  activityController.getAllActivities
);

// ======================================================
// 🔵 جلب نشاط واحد بالـ ID (صلاحية: canViewActivities)
// ======================================================
router.get(
  '/:id',
  verifyToken,
  authorizePermission('canViewActivities'),
  logRequest,
  activityController.getActivityById
);

// ======================================================
// 🟠 تحديث نشاط (صلاحية: canManageActivities)
// ======================================================
// ======================================================
// 🟠 تحديث نشاط (صلاحية: canManageActivities)
// ======================================================
router.put(
  '/:id',
  verifyToken,
  authorizePermission('canManageActivities'),
  logRequest,
  upload.fields([
    { name: 'image', maxCount: 1 },
    { name: 'form', maxCount: 1 },
  ]),
  (req, res) => {
    try {
      activityController.updateActivity(req, res);
    } catch (err) {
      console.error("❌ Update error:", err);
      res.status(400).json({ success: false, message: err.message });
    }
  }
);


// ======================================================
// 🔴 حذف نشاط (صلاحية: canDeleteActivity)
// ======================================================
router.delete(
  '/:id',
  verifyToken,
  authorizePermission('canDeleteActivity'),
  logRequest,
  activityController.deleteActivity
);

module.exports = router;
