//  routes/calendar.routes.js
const express = require('express');
const router = express.Router();

const verifyToken = require('../middleware/verifyToken');
const authorizePermission = require('../middleware/authorizePermission');
const calendarController = require('../controllers/calendar.controller');

// ======================================================
//  جلب تقويم الطالب حسب الشهر
//  Permission: canViewActivities
// ======================================================
router.get(
  '/calendar/month/:studentUniId',
  verifyToken,
  authorizePermission('canViewActivities'),
  calendarController.getCalendarByMonth
);

// ======================================================
//  جلب تقويم الطالب كامل
//  Permission: canViewActivities
// ======================================================
router.get(
  '/calendar/all/:studentUniId',
  verifyToken,
  authorizePermission('canViewActivities'),
  calendarController.getCalendarAll
);

module.exports = router;
