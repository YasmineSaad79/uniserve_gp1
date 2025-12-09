const db = require("../db");

const CustomRequests = {
  create: (studentId, title, description, callback) => {
    const sql = `
      INSERT INTO student_custom_requests (student_id, title, description)
      VALUES (?, ?, ?)
    `;
    db.query(sql, [studentId, title, description], callback);
  },

  updateStatus: (id, status, callback) => {
    db.query(
      `UPDATE student_custom_requests SET status = ? WHERE request_id = ?`,
      [status, id],
      callback
    );
  }
};

module.exports = CustomRequests;
