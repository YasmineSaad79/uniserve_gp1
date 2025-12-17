//  routes/searchRoutes.js
const express = require("express");
const router = express.Router();

const { globalSearch } = require("../controllers/searchController");
const verifyToken = require("../middleware/verifyToken");
const authorizePermission = require("../middleware/authorizePermission");

// ======================================================
//  البحث العام في النظام
//  Permission: canViewActivities
// ======================================================
router.get(
  "/",
  verifyToken,
  authorizePermission("canViewActivities"),
  globalSearch
);

module.exports = router;
