const db = require("../db");

const Notifications = {
  create: (data, callback) => {
    const sql = `
      INSERT INTO notifications (type, receiver_id, sender_user_id, activity_id, title, body, payload)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `;
    db.query(sql, [
      data.type,
      data.receiver_id,
      data.sender_user_id,
      data.activity_id,
      data.title,
      data.body,
      JSON.stringify(data.payload || {})
    ], callback);
  },

  getForUser: (userId, callback) => {
    db.query(
      `SELECT * FROM notifications WHERE receiver_id = ? ORDER BY created_at DESC`,
      [userId],
      callback
    );
  },

  markRead: (id, callback) => {
    db.query(
      `UPDATE notifications SET is_read = 1, read_at = NOW() WHERE id = ?`,
      [id],
      callback
    );
  }
};

module.exports = Notifications;
