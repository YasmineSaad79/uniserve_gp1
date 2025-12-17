//  routes/recommendationRoutes.js
const express = require("express");
const router = express.Router();

const recommendationController = require("../controllers/recommendationController");
const verifyToken = require("../middleware/verifyToken");
const authorizePermission = require("../middleware/authorizePermission");

// ======================================================
//  Get AI Recommendations for a Student
//  Permission: canViewActivities
// ======================================================
router.get(
  "/students/:studentId/recommendations",
  verifyToken,
  authorizePermission("canViewActivities"),
  recommendationController.getRecommendations
);

module.exports = router;
