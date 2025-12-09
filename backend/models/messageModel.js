// ============================
// 📁 backend/models/messageModel.js
// ============================
const db = require("../db"); // اتصال MySQL (mysql أو mysql2/promise ملفك أنتِ)

const Message = {
  /**
   * ✅ إنشاء رسالة جديدة
   * @param {number} senderId 
   * @param {number} receiverId 
   * @param {string} content 
   * @param {(err, result) => void} callback 
   */
 create: (senderId, receiverId, content, attachmentUrl, callback) => {
  const sql = `
    INSERT INTO messages (sender_id, receiver_id, content, attachment_url)
    VALUES (?, ?, ?, ?)
  `;
  db.query(
    sql,
    [senderId, receiverId, content, attachmentUrl],
    (err, result) => {
      if (err) return callback(err);
      callback(null, { message_id: result.insertId });
    }
  );
},


  /**
   * ✅ جلب المحادثة بين مستخدمين (مرسَل/مستقبِل)
   * + تحديث الرسائل غير المقروءة لتصبح مقروءة عند فتح الشات
   */
  getConversation: (user1, user2, callback) => {
    const sql = `
      SELECT m.*,
             s.full_name AS sender_name,
             r.full_name AS receiver_name
      FROM messages m
      JOIN users s ON s.id = m.sender_id
      JOIN users r ON r.id = m.receiver_id
      WHERE (m.sender_id = ? AND m.receiver_id = ?)
         OR (m.sender_id = ? AND m.receiver_id = ?)
      ORDER BY m.sent_at ASC
    `;

    db.query(sql, [user1, user2, user2, user1], (err, rows) => {
      if (err) return callback(err);

      // 🔹 تحديث حالة الرسائل غير المقروءة (is_read = 1)
      const updateSql = `
        UPDATE messages
        SET is_read = 1
        WHERE receiver_id = ? AND sender_id = ? AND is_read = 0
      `;
      db.query(updateSql, [user1, user2], (updateErr) => {
        if (updateErr) console.error("⚠️ Error updating read status:", updateErr);
      });

      callback(null, rows);
    });
  },

  /**
   * ✅ تعليم رسالة معينة كمقروءة
   */
  markAsRead: (messageId, callback) => {
    const sql = `UPDATE messages SET is_read = 1 WHERE message_id = ?`;
    db.query(sql, [messageId], callback);
  },

  /**
   * ✅ عدّاد الرسائل غير المقروءة لمستخدم معيّن
   */
  countUnreadForUser: (userId, callback) => {
    const sql = `
      SELECT COUNT(*) AS unread_count
      FROM messages
      WHERE receiver_id = ? AND is_read = 0
    `;
    db.query(sql, [userId], (err, rows) => {
      if (err) return callback(err);
      callback(null, rows[0]);
    });
  }
};

module.exports = Message;
