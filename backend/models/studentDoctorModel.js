const db = require("../db");

const StudentDoctor = {
  getDoctorForStudent: (studentUserId, callback) => {
    const sql = `
      SELECT d.*
      FROM student_doctor sd
      JOIN users d ON d.id = sd.doctor_user_id
      WHERE sd.student_user_id = ?
    `;
    db.query(sql, [studentUserId], callback);
  }
};

module.exports = StudentDoctor;
