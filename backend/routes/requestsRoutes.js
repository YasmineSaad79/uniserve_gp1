//  routes/requestsRoutes.js
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

// ======================================================
//  Volunteer Requests
// ======================================================

//  جلب طلبات التطوع
// Permission: canViewActivities
router.get(
  "/volunteer",
  verifyToken,
  authorizePermission("canViewActivities"),
  getVolunteerRequests
);

//  قبول طلب تطوع
//  Permission: canApproveActivity
router.put(
  "/volunteer/accept/:id",
  verifyToken,
  authorizePermission("canApproveActivity"),
  acceptVolunteerRequest
);

//  رفض طلب تطوع
//  Permission: canApproveActivity
router.put(
  "/volunteer/reject/:id",
  verifyToken,
  authorizePermission("canApproveActivity"),
  rejectVolunteerRequest
);

// ======================================================
//  Custom Requests
// ======================================================

//  جلب الطلبات المخصصة
//  Permission: canViewActivities
router.get(
  "/custom",
  verifyToken,
  authorizePermission("canViewActivities"),
  getCustomRequests
);

//  تحديث حالة طلب مخصص
//  Permission: canUpdateCustomRequests
router.patch(
  "/custom/:id/status",
  verifyToken,
  authorizePermission("canUpdateCustomRequests"),
  updateCustomRequestStatus
);

// ======================================================
//  Approved Requests
// ======================================================

//  جلب طلبات التطوع المقبولة
//  Permission: canViewActivities

router.get(
  "/approved/volunteer",
  verifyToken,
  authorizePermission("canViewActivities"),
  getApprovedVolunteerRequests
);

//  جلب الطلبات المخصصة المقبولة
//  Permission: canViewActivities
router.get(
  "/approved/custom",
  verifyToken,
  authorizePermission("canViewActivities"),
  getApprovedCustomRequests
);

module.exports = router;
