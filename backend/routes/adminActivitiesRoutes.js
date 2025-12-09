

const express = require("express");
const router = express.Router();
const userController = require("../controllers/adminActivitiesController");
const bcrypt = require("bcryptjs");
const crypto = require("crypto");
const nodemailer = require("nodemailer");
const db = require("../db");
const verifyToken = require("../middleware/verifyToken");   // ✅ هذا السطر لازم
const authorizePermission = require("../middleware/authorizePermission");



router.post(
  "/admin/assign-student",
  verifyToken,
  authorizePermission("canManageStudents"), // ❗ الصلاحية المطلوبة
  userController.assignStudentToDoctor
);

router.get(
  "/admin/doctor/:doctorId/students",
  verifyToken,
  authorizePermission("canManageStudents"), // ❗ نفس الصلاحية
  userController.getDoctorStudents
);


module.exports = router;
