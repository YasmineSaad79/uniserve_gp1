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

// Get profile
router.get(
  "/profile/:doctorId",
  verifyToken,
  authorizePermission("canViewProfile"),
  doctorController.getDoctorProfile
);

// Update profile (name + phone + optional photo SAME endpoint)
router.put(
  "/profile/:doctorId",
  verifyToken,
  authorizePermission("canEditProfile"),
  upload.single("photo"),
  doctorController.updateDoctorProfile
);

// Change password
router.put(
  "/profile/password/:doctorId",
  verifyToken,
  authorizePermission("canEditProfile"),
  doctorController.changePassword
);

// Students under a doctor
router.get(
  "/my-students",
  verifyToken,
  authorizePermission("canViewStudents"),
  doctorController.getDoctorStudentsForDoctor
);

module.exports = router;
