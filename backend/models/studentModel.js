const db = require("../db");

const Students = {
  create: (studentId, userId, callback) => {
    const sql = `
      INSERT INTO students (student_id, user_id)
      VALUES (?, ?)
    `;
    db.query(sql, [studentId, userId], callback);
  },

  getProfileByStudentId: (studentId, callback) => {
    const sql = `
      SELECT u.*, s.phone_number, s.preferences, s.hobbies
      FROM students s
      JOIN users u ON u.id = s.user_id
      WHERE s.student_id = ?
    `;
    db.query(sql, [studentId], callback);
  }
};

module.exports = Students;
