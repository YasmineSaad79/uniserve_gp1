// routes/aiCenterRoutes.js
const express = require("express");
const router = express.Router();

const verifyToken = require("../middleware/verifyToken"); // نفس اللي استخدمناه مع البروفايل :contentReference[oaicite:2]{index=2}
const aiCenterController = require("../controllers/aiCenterController");

// 🔹 تحليل تشابه طلب معيّن مع خدمات المركز
router.get(
  "/center/requests/:requestId/similarity",
  verifyToken,
  aiCenterController.analyzeCustomRequestSimilarity
);

module.exports = router;
