//  routes/doctorRoutes.js
const express = require("express");
const router = express.Router();
const path = require("path");
const multer = require("multer");

const doctorController = require("../controllers/doctorController");
const verifyToken = require("../middleware/verifyToken");
const authorizePermission = require("../middleware/authorizePermission");

// ======================
//  MULTER config
// ======================
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, path.join(__dirname, "..", "uploads"));
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + "-" + file.originalname);
  },
});
const upload = multer({ storage });

// ======================
//  ROUTES
// ======================

// ------------------------------------------------------
//  جلب بروفايل دكتور
//  Permission: canViewProfile
// ------------------------------------------------------
router.get(
  "/profile/:doctorId",
  verifyToken,
  authorizePermission("canViewProfile"),
  doctorController.getDoctorProfile
);

// ------------------------------------------------------
//  تحديث بروفايل دكتور (اسم + هاتف + صورة)
//  Permission: canEditProfile
// ------------------------------------------------------
router.put(
  "/profile/:doctorId",
  verifyToken,
  authorizePermission("canEditProfile"),
  upload.single("photo"),
  doctorController.updateDoctorProfile
);

// ------------------------------------------------------
//  تغيير كلمة المرور
//  Permission: canEditProfile
// ------------------------------------------------------
router.put(
  "/profile/password/:doctorId",
  verifyToken,
  authorizePermission("canEditProfile"),
  doctorController.changePassword
);

// ------------------------------------------------------
//  جلب طلاب الدكتور
//  Permission: canViewStudents
// ------------------------------------------------------
router.get(
  "/my-students",
  verifyToken,
  authorizePermission("canViewStudents"),
  doctorController.getDoctorStudentsForDoctor
);

module.exports = router;
