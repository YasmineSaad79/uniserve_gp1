// ============================
// 📁 backend/controllers/messageController.js
// ============================
const db = require("../db");
const Message = require("../models/messageModel");
const admin = require("../config/firebase"); // Firebase Admin
const { sendPushToUser } = require("./notificationsController");

// دالة مساعدة لتوحيد الردود
const sendResponse = (res, success, message, data = null, code = 200) => {
  res.status(code).json({ success, message, data });
};

const MessageController = {
  // ======================================================
  // 🟢 إرسال رسالة جديدة (نص + ملف اختياري) + إشعار FCM
  // ======================================================
// 🟢 إرسال رسالة جديدة (نص + ملف اختياري) + إشعار FCM
sendMessage: async (req, res) => {
  try {
const { sender_id, receiver_id, content } = req.body;


    // رابط الملف إذا تم رفعه
    const attachmentUrl = req.file
      ? `/uploads/messages/${req.file.filename}`
      : null;

    if (!sender_id || !receiver_id) {
      return sendResponse(
        res,
        false,
        "Missing required fields",
        null,
        400
      );
    }

    // إنشاء الرسالة في قاعدة البيانات
    const result = await new Promise((resolve, reject) => {
      Message.create(
        sender_id,
        receiver_id,
        content || "",
        attachmentUrl,
        (err, dbResult) => {
          if (err) return reject(err);
          resolve(dbResult);
        }
      );
    });

    // اسم المرسل
    const [userRows] = await db
      .promise()
      .query("SELECT full_name FROM users WHERE id = ?", [sender_id]);

    const senderName = userRows[0]?.full_name || "New message";

    // إرسال إشعار
   await sendPushToUser(
  receiver_id, // ← الطرف اللي لازم يصله الإشعار
  `💬 New message from ${senderName}`,
  content ? content.substring(0, 80) : "Sent an attachment",
  {
    type: "chat",
    sender_id: String(sender_id),
    receiver_id: String(receiver_id),
  }
);


    return sendResponse(
      res,
      true,
      "Message sent successfully",
      {
        message_id: result.insertId,
        sender_id,
        receiver_id,
        content,
        attachment_url: attachmentUrl,
      },
      201
    );
  } catch (err) {
    console.error("❌ sendMessage Exception:", err);
    return sendResponse(
      res,
      false,
      "Internal server error",
      null,
      500
    );
  }
},

  // ======================================================
  // 🔵 جلب محادثة بين مستخدمين
  // ======================================================
  getConversation: (req, res) => {
    try {
      const { user1, user2 } = req.params;
      Message.getConversation(user1, user2, (err, rows) => {
        if (err) {
          console.error("❌ getConversation:", err);
          return res.status(500).json({ message: "Database fetch error" });
        }
        return res.json(rows);
      });
    } catch (err) {
      console.error("❌ getConversation Exception:", err);
      return res.status(500).json({ message: "Internal server error" });
    }
  },

  // ======================================================
  // 🟣 تعليم رسالة كمقروءة
  // ======================================================
  markRead: (req, res) => {
    try {
      const { id } = req.params;
      Message.markAsRead(id, (err) => {
        if (err) {
          console.error("❌ markRead:", err);
          return sendResponse(
            res,
            false,
            "Database update error",
            null,
            500
          );
        }
        return sendResponse(res, true, "Message marked as read");
      });
    } catch (err) {
      console.error("❌ markRead Exception:", err);
      return sendResponse(
        res,
        false,
        "Internal server error",
        null,
        500
      );
    }
  },

  // ======================================================
  // 🟡 عدد الرسائل غير المقروءة لمستخدم
  // ======================================================
  unreadCount: (req, res) => {
    try {
      const { userId } = req.params;
      Message.countUnreadForUser(userId, (err, row) => {
        if (err) {
          console.error("❌ unreadCount:", err);
          return sendResponse(
            res,
            false,
            "Database count error",
            null,
            500
          );
        }
        return sendResponse(
          res,
          true,
          "Unread count fetched",
          row
        );
      });
    } catch (err) {
      console.error("❌ unreadCount Exception:", err);
      return sendResponse(
        res,
        false,
        "Internal server error",
        null,
        500
      );
    }
  },

  // ======================================================
  // 🆕 unreadGrouped (للواجهة مع آخر رسالة وتاريخها)
  // ======================================================
  unreadGrouped: (req, res) => {
    try {
      const { userId } = req.params;

      const sql = `
        SELECT 
          u.id AS sender_id,
          u.full_name,
          u.email,
          u.photo_url,
          COUNT(CASE WHEN m.is_read = 0 AND m.receiver_id = ? THEN 1 END) AS unreadCount,
          (
            SELECT m2.sent_at
            FROM messages m2
            WHERE 
              (m2.sender_id = u.id AND m2.receiver_id = ?) 
              OR (m2.sender_id = ? AND m2.receiver_id = u.id)
            ORDER BY m2.sent_at DESC
            LIMIT 1
          ) AS lastMessageTime,
          (
            SELECT COALESCE(m3.content, '[Attachment]')
            FROM messages m3
            WHERE 
              (m3.sender_id = u.id AND m3.receiver_id = ?) 
              OR (m3.sender_id = ? AND m3.receiver_id = u.id)
            ORDER BY m3.sent_at DESC
            LIMIT 1
          ) AS lastMessageContent
        FROM users u
        LEFT JOIN messages m 
          ON m.sender_id = u.id OR m.receiver_id = u.id
        WHERE u.id != ?
        GROUP BY u.id, u.full_name, u.email, u.photo_url
      `;

      db.query(
        sql,
        [userId, userId, userId, userId, userId, userId],
        (err, rows) => {
          if (err) {
            console.error("❌ unreadGrouped:", err);
            return sendResponse(
              res,
              false,
              "Database fetch error",
              null,
          
            );
          }
          return sendResponse(
            res,
            true,
            "Grouped unread messages fetched",
            rows
          );
        }
      );
    } catch (err) {
      console.error("❌ unreadGrouped Exception:", err);
      return sendResponse(
        res,
        false,
        "Internal server error",
        null,
        500
      );
    }
  },
};

module.exports = MessageController;
