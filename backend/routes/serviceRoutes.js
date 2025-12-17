const express = require("express");
const router = express.Router();

const verifyToken = require("../middleware/verifyToken");
const authorizePermission = require("../middleware/authorizePermission");
const serviceController = require("../controllers/serviceController");

// ======================================================
//  جلب طلاب المركز الخدمي
//  Permission: canViewStudents
// ======================================================
router.get(
  "/students",
  verifyToken,
  authorizePermission("canViewStudents"),
  serviceController.getCenterStudents
);

module.exports = router;
