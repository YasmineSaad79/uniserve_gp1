const db = require("../db");

const Emails = {
  send: (sender, receiver, subject, body, callback) => {
    const sql = `
      INSERT INTO emails (sender_id, receiver_id, subject, body)
      VALUES (?, ?, ?, ?)
    `;
    db.query(sql, [sender, receiver, subject, body], callback);
  },

  getInbox: (userId, callback) => {
    const sql = `
      SELECT e.*, s.full_name AS sender_name
      FROM emails e
      JOIN users s ON s.id = e.sender_id
      WHERE receiver_id = ?
      ORDER BY sent_at DESC
    `;
    db.query(sql, [userId], callback);
  }
};

module.exports = Emails;
