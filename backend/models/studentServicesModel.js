const db = require("../db");

const StudentServices = {
  joinService: (studentId, serviceId, callback) => {
    db.query(
      `INSERT INTO student_services (student_id, service_id)
       VALUES (?, ?)`,
      [studentId, serviceId], callback
    );
  },

  updateApproval: (id, status, callback) => {
    db.query(
      `UPDATE student_services SET approval_status = ? WHERE id = ?`,
      [status, id], callback
    );
  }
};

module.exports = StudentServices;
