//  routes/adminActivitiesRoutes.js
const express = require("express");
const router = express.Router();

const adminActivitiesController = require("../controllers/adminActivitiesController");
const verifyToken = require("../middleware/verifyToken");
const authorizePermission = require("../middleware/authorizePermission");

// ======================================================
//  تعيين طالب لدكتور
//  Permission: canManageStudents
// ======================================================
router.post(
  "/admin/assign-student",
  verifyToken,
  authorizePermission("canManageStudents"),
  adminActivitiesController.assignStudentToDoctor
);

// ======================================================
//  جلب طلاب دكتور معين
// Permission: canManageStudents
// ======================================================
router.get(
  "/admin/doctor/:doctorId/students",
  verifyToken,
  authorizePermission("canManageStudents"),
  adminActivitiesController.getDoctorStudents
);

module.exports = router;
