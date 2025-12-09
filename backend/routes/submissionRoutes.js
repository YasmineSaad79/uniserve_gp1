const express = require("express");
const router = express.Router();
const verifyToken = require("../middleware/verifyToken");
const uploadSubmission = require("../middleware/uploadSubmission");

const {
  getStudentSubmission,
  uploadSubmissionFile,
  getCenterSubmissions,
  getStudentAllSubmissions,
  approveSubmission,
    rejectSubmission,   

  getCenterSummary


} = require("../controllers/submissionController");

router.get(
  "/student/:studentId/activity/:activityId",
  verifyToken,
  getStudentSubmission
);

router.post(
  "/upload",
  verifyToken,
  uploadSubmission.single("submission_file"),
  uploadSubmissionFile
);

// 🟣 NEW — Get all submissions for student
router.get("/student/:studentId/all", getStudentAllSubmissions);


router.get("/center", verifyToken, getCenterSubmissions);
router.put("/approve/:id", verifyToken, approveSubmission);
router.put("/reject/:id", verifyToken, rejectSubmission);

router.get("/center-summary", verifyToken, getCenterSummary);

module.exports = router;
