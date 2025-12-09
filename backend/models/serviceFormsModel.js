const db = require("../db");

const ServiceForms = {
  uploadForm: (studentId, serviceId, filePath, callback) => {
    const sql = `
      INSERT INTO service_forms (student_id, service_id, file_path)
      VALUES (?, ?, ?)
    `;
    db.query(sql, [studentId, serviceId, filePath], callback);
  }
};

module.exports = ServiceForms;
