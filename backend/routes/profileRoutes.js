//  routes/profileRoutes.js
const express = require("express");
const router = express.Router();

const profileController = require("../controllers/profileController");
const upload = require("../middleware/uploadMiddleware");

//  Middlewares
const verifyToken = require("../middleware/verifyToken");
const authorizePermission = require("../middleware/authorizePermission");

// ======================================================
//  جلب بيانات المستخدم حسب ID
//  Permission: canViewProfile
// ======================================================
router.get(
  "/:id",
  verifyToken,
  authorizePermission("canViewProfile"),
  profileController.getProfileById
);

// ======================================================
//  تحديث صورة البروفايل
//  Permission: canUploadPhoto
// ======================================================
router.put(
  "/photo",
  verifyToken,
  authorizePermission("canUploadPhoto"),
  upload.single("photo"),
  profileController.updatePhoto
);

module.exports = router;
