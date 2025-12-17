
const express = require("express");
const router = express.Router();

const { getStudentsForService } = require("../controllers/all_studentController");
const verifyToken = require("../middleware/verifyToken");
const authorizePermission = require("../middleware/authorizePermission");

// ======================================================
//  جلب الطلاب التابعين لمركز الخدمة
//  Permission: canViewStudents
// ======================================================
router.get(
  "/students",
  verifyToken,
  authorizePermission("canViewStudents"),
  getStudentsForService
);

module.exports = router;
