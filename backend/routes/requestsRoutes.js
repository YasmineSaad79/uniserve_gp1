const express = require("express");
const router = express.Router();
const verifyToken = require("../middleware/verifyToken");
const authorizePermission = require("../middleware/authorizePermission");

const {
  getVolunteerRequests,
  acceptVolunteerRequest,
  rejectVolunteerRequest,
  getCustomRequests,
  getApprovedVolunteerRequests,
  getApprovedCustomRequests,
  updateCustomRequestStatus
} = require("../controllers/requestsController");

// Volunteer
router.get("/volunteer", verifyToken, getVolunteerRequests);
router.put("/volunteer/accept/:id", verifyToken, acceptVolunteerRequest);
router.put("/volunteer/reject/:id", verifyToken, rejectVolunteerRequest);

// Custom
router.get("/custom", verifyToken, getCustomRequests);
router.patch(
  "/custom/:id/status",
  verifyToken,
  authorizePermission("canUpdateCustomRequests")
,
  updateCustomRequestStatus
);

// Approved
router.get("/approved/volunteer", verifyToken, getApprovedVolunteerRequests);
router.get("/approved/custom", verifyToken, getApprovedCustomRequests);

module.exports = router;
