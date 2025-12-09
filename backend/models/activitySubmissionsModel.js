const db = require("../db");

const ActivitySubmissions = {
  submitFile: (data, callback) => {
    const sql = `
      INSERT INTO activity_submissions (student_id, activity_id, submitted_file_path)
      VALUES (?, ?, ?)
    `;
    db.query(sql, [data.student_id, data.activity_id, data.path], callback);
  },

  getSubmission: (studentId, activityId, callback) => {
    const sql = `
      SELECT * FROM activity_submissions
      WHERE student_id = ? AND activity_id = ?
    `;
    db.query(sql, [studentId, activityId], callback);
  },

  updateStatus: (submissionId, status, callback) => {
    db.query(`UPDATE activity_submissions SET status = ? WHERE submission_id = ?`,
      [status, submissionId], callback);
  }
};

module.exports = ActivitySubmissions;
