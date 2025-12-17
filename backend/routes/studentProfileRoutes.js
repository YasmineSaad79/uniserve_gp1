const express = require("express");
const router = express.Router();

const studentProfileController = require("../controllers/studentProfileController");
const upload = require("../middleware/upload");

const verifyToken = require("../middleware/verifyToken");
const authorizePermission = require("../middleware/authorizePermission");

// ======================================================
//  جلب بروفايل الطالب
//  Permission: canViewProfile
// ======================================================
router.get(
  "/profile/:studentId",
  verifyToken,
  authorizePermission("canViewProfile"),
  studentProfileController.getStudentProfile
);

// ======================================================
//  تحديث بيانات الطالب + صورة
//  Permission: canEditProfile
// ======================================================
router.put(
  "/profile/:studentId",
  verifyToken,
  authorizePermission("canEditProfile"),
  upload.single("photo"),
  studentProfileController.updateStudentProfile
);

// ======================================================
//  جلب user_id من student_id
//  Permission: canViewProfile
// ======================================================
router.get(
  "/user-id/:studentId",
  verifyToken,
  authorizePermission("canViewProfile"),
  studentProfileController.getUserIdByStudentId
);

module.exports = router;
