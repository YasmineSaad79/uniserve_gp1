//  routes/password.route.js
const express = require("express");
const router = express.Router();

const passwordController = require("../controllers/passwordController");
const verifyToken = require("../middleware/verifyToken");
const authorizePermission = require("../middleware/authorizePermission");

// ======================================================
//  تغيير كلمة المرور
//  Permission: canEditProfile
// ======================================================
router.put(
  "/",
  verifyToken,
  authorizePermission("canEditProfile"),
  passwordController.changePassword
);

module.exports = router;
