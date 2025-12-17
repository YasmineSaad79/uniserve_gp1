//  routes/serviceCalendarRoutes.js
const express = require("express");
const router = express.Router();

const verifyToken = require("../middleware/verifyToken");
const authorizePermission = require("../middleware/authorizePermission");
const serviceCalendarController = require("../controllers/serviceCalendarController");

// ======================================================
// جلب تقويم الأنشطة (Service Calendar)
// Permission: canViewActivities
// ======================================================
router.get(
  "/activities/calendar",
  verifyToken,
  authorizePermission("canViewActivities"),
  serviceCalendarController.getCalendarActivities
);

// ======================================================
//  إضافة Reminder
//  Permission: canManageActivities
// ======================================================
router.post(
  "/reminders",
  verifyToken,
  authorizePermission("canManageActivities"),
  serviceCalendarController.addReminder
);

module.exports = router;
