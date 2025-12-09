const db = require("../db");

const VolunteerRequests = {
  create: (studentId, activityId, callback) => {
    const sql = `
      INSERT INTO volunteer_requests (student_id, activity_id)
      VALUES (?, ?)
    `;
    db.query(sql, [studentId, activityId], callback);
  },

  getByStudent: (studentId, callback) => {
    const sql = `
      SELECT vr.*, s.title AS activity_title
      FROM volunteer_requests vr
      JOIN services s ON s.service_id = vr.activity_id
      WHERE vr.student_id = ?
    `;
    db.query(sql, [studentId], callback);
  },

  updateStatus: (id, status, callback) => {
    db.query(`UPDATE volunteer_requests SET status = ? WHERE id = ?`,
      [status, id], callback);
  }
};

module.exports = VolunteerRequests;
