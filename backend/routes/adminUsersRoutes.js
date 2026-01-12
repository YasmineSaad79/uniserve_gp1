// ===============================================
// backend/routes/adminUsersRoutes.js
// ===============================================

const express = require("express");
const router = express.Router();

const adminUsersController = require("../controllers/adminUsersController");
const verifyToken = require("../middleware/verifyToken");
const authorizePermission = require("../middleware/authorizePermission");

// ============================
// Get all users
// Permission: canManageEverything
// ============================
router.get(
  "/admin/users",
  verifyToken,
  authorizePermission("canManageEverything"),
  adminUsersController.getAllUsers
);

// ============================
// Deactivate user
// Permission: canManageEverything
// ============================
router.put(
  "/admin/users/:userId/deactivate",
  verifyToken,
  authorizePermission("canManageEverything"),
  adminUsersController.deactivateUser
);

// ============================
// Activate user
// Permission: canManageEverything
// ============================
router.put(
  "/admin/users/:userId/activate",
  verifyToken,
  authorizePermission("canManageEverything"),
  adminUsersController.activateUser
);
// ============================
// Change user role
// Permission: canManageUsers (or canManageEverything)
// ============================
router.put(
  "/admin/users/:userId/role",
  verifyToken,
  authorizePermission("canManageEverything"),
  adminUsersController.changeUserRole
);

module.exports = router;
