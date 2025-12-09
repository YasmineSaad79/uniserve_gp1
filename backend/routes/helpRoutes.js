const express = require("express");
const router = express.Router();
const helpController = require("../controllers/helpController");
const verifyToken = require("../middleware/verifyToken");
const authorizePermission = require("../middleware/authorizePermission");

// ✅ جلب الأسئلة الشائعة
router.get("/faqs", helpController.getFaqs);

// ✅ إضافة سؤال شائع
router.post("/faqs", helpController.addFaq);

// ✅ إرسال سؤال من الطالب
router.post("/student-question", helpController.submitQuestion);

// ✅ للسنتر: جلب كل الأسئلة
router.get(
  "/student-questions",
  verifyToken,
  authorizePermission("canViewQuestions"),
  helpController.getAllStudentQuestions
);

// ✅ رد السنتر على سؤال
router.put(
  "/student-questions/:id/reply",
  verifyToken,
  authorizePermission("canReplyQuestions"),
  helpController.replyToQuestion
);

// ✅ للطالب: جلب أسئلته فقط
router.get(
  "/my-questions/:studentId",
  verifyToken,
  authorizePermission("canViewOwnQuestions"),
  helpController.getMyQuestions
);

module.exports = router;
