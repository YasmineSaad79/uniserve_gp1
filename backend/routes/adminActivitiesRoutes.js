//  routes/adminActivitiesRoutes.js
const express = require("express");
const router = express.Router();
const multer = require("multer");
const upload = multer({ dest: "uploads/" });

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
router.get(
  "/users/get-userid-by-uni/:uniId",
  verifyToken,
  authorizePermission("canManageStudents"),
  adminActivitiesController.getUserIdByUniversityId
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
router.post(
  "/admin/import-students",
  verifyToken,
  authorizePermission("canManageStudents"),
  upload.single("file"),
  adminActivitiesController.importStudentsFromExcel
);
module.exports = router;
