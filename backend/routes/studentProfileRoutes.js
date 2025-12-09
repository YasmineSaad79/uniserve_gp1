// 📁 backend/routes/studentProfileRoutes.js

const express = require("express");
const router = express.Router();
const studentProfileController = require("../controllers/studentProfileController");
const upload = require("../middleware/upload");

// ✅ جلب بروفايل الطالب
router.get("/profile/:studentId", studentProfileController.getStudentProfile);

// ✅ تحديث بيانات الطالب مع الصورة
router.put(
  "/profile/:studentId",
  upload.single("photo"),
  studentProfileController.updateStudentProfile
);

// ✅ جلب user_id من student_id
router.get('/user-id/:studentId', studentProfileController.getUserIdByStudentId);

module.exports = router;
