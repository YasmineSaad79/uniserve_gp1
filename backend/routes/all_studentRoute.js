// 📁 backend/routes/serviceRoutes.js
const express = require("express");
const router = express.Router();
const { getStudentsForService } = require("../controllers/all_studentController"); // ✅ لاحظي الاسم
const authorizePermission = require('../middleware/authorizePermission');
const verifyToken = require('../middleware/verifyToken');

router.get(
  "/students",
  verifyToken,
  authorizePermission("canViewStudents"),
  getStudentsForService
);

module.exports = router;
