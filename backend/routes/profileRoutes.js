const express = require("express");
const router = express.Router();
const profileController = require("../controllers/profileController");
const upload = require("../middleware/uploadMiddleware");

// ✅ ميدلويرات التحقق
const verifyToken = require("../middleware/verifyToken");
const authorizePermission = require("../middleware/authorizePermission");

// ✅ جلب بيانات المستخدم حسب ID
router.get("/:id", verifyToken, authorizePermission("canViewProfile"), profileController.getProfileById);

// ✅ رفع الصورة مع التوكن والصلاحية
router.put(
  "/photo",
  upload.single("photo"),
  profileController.updatePhoto
);


module.exports = router;
