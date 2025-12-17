//  routes/aiCenterRoutes.js
const express = require("express");
const router = express.Router();

const verifyToken = require("../middleware/verifyToken");
const authorizePermission = require("../middleware/authorizePermission");
const aiCenterController = require("../controllers/aiCenterController");

// ======================================================
//  تحليل تشابه طلب معيّن مع خدمات المركز
//  Permission: canUpdateCustomRequests
// ======================================================
router.get(
  "/center/requests/:requestId/similarity",
  verifyToken,
  authorizePermission("canUpdateCustomRequests"),
  aiCenterController.analyzeCustomRequestSimilarity
);

module.exports = router;
