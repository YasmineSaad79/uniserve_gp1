//  routes/aiSearchRoutes.js
const express = require("express");
const router = express.Router();

const { aiSearch } = require("../controllers/aiSearchController");
const verifyToken = require("../middleware/verifyToken");
const authorizePermission = require("../middleware/authorizePermission");

// ======================================================
//  AI Search Query
//  Permission: canViewActivities
// ======================================================
router.post(
  "/query",
  verifyToken,
  authorizePermission("canViewActivities"),
  aiSearch
);

module.exports = router;
