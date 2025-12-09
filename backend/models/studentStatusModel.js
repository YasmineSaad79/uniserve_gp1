const db = require("../db");

const StudentStatus = {
  evaluate: (data, callback) => {
    const sql = `
      INSERT INTO student_status (student_id, service_id, supervisor_id, result, comments)
      VALUES (?, ?, ?, ?, ?)
    `;
    db.query(sql, [
      data.student_id,
      data.service_id,
      data.supervisor_id,
      data.result,
      data.comments
    ], callback);
  }
};

module.exports = StudentStatus;
