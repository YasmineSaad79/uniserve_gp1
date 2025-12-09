const db = require("../db");

const StudentQuestions = {
  create: (userId, studentId, question, callback) => {
    const sql = `
      INSERT INTO student_questions (user_id, student_id, question)
      VALUES (?, ?, ?)
    `;
    db.query(sql, [userId, studentId, question], callback);
  },

  reply: (id, reply, callback) => {
    const sql = `
      UPDATE student_questions
      SET reply = ?, replied_at = NOW(), is_answered = 1
      WHERE id = ?
    `;
    db.query(sql, [reply, id], callback);
  }
};

module.exports = StudentQuestions;
