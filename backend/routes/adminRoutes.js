//  routes/adminDashboardRoutes.js
const express = require("express");
const router = express.Router();

const adminDashboardController = require("../controllers/adminDashboardController");
const verifyToken = require("../middleware/verifyToken");
const authorizePermission = require("../middleware/authorizePermission");

// ======================================================
//  Admin Dashboard (Premium)
//  Permission: canManageEverything
// ======================================================
router.get(
  "/dashboard",
  verifyToken,
  authorizePermission("canManageEverything"),
  adminDashboardController.getAdminDashboard
);

module.exports = router;
