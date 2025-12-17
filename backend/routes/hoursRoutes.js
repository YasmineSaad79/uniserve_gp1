//  routes/hoursRoutes.js
const express = require("express");
const router = express.Router();

const hoursController = require("../controllers/hoursController");
const verifyToken = require("../middleware/verifyToken");
const authorizePermission = require("../middleware/authorizePermission");

// ======================================================
//  Service Center
// معالجة ساعات التطوع (زر واحد)
//  Permission: canProcessHours
// ======================================================
router.post(
  "/process",
  verifyToken,
  authorizePermission("canProcessHours"),
  hoursController.processHours
);

// ======================================================
//  Doctor
// عرض ملخص الساعات للطلاب المرتبطين به
//  Permission: canViewStudents
// ======================================================
router.get(
  "/doctor-summary",
  verifyToken,
  authorizePermission("canViewStudents"),
  hoursController.getDoctorSummary
);

module.exports = router;
