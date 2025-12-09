const express = require("express");
const router = express.Router();
const recommendationController = require("../controllers/recommendationController");
const verifyToken = require("../middleware/verifyToken");  // ✅ أهم سطر

// GET → Get recommendations for a student
router.get(
  "/students/:studentId/recommendations",
  verifyToken, // 🔥 middleware
  recommendationController.getRecommendations
);

module.exports = router;
