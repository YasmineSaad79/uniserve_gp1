const express = require("express");
const router = express.Router();

const verifyToken = require("../middleware/verifyToken");
const MessageController = require("../controllers/messageController");
const upload = require("../middleware/upload");

// 🟣 حماية كل مسارات الرسائل:
router.use(verifyToken);

// إرسال رسالة (نص + مرفق)
router.post(
  "/send",
  upload.single("attachment"),
  MessageController.sendMessage
);

// جلب المحادثة
router.get(
  "/conversation/:user1/:user2",
  MessageController.getConversation
);

// unread count
router.get("/unread-count/:userId", MessageController.unreadCount);

// unread grouped
router.get("/unread-grouped/:userId", MessageController.unreadGrouped);

// mark read
router.patch("/:id/read", MessageController.markRead);

module.exports = router;
