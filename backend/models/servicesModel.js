const db = require("../db");

const Services = {
  create: (data, callback) => {
    const sql = `
      INSERT INTO services (title, description, location, created_by, start_date, end_date, status, progress_points, image_url, form_template_path)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;
    db.query(sql, [
      data.title,
      data.description,
      data.location,
      data.created_by,
      data.start_date,
      data.end_date,
      data.status,
      data.progress_points,
      data.image_url,
      data.form_template_path
    ], callback);
  },

  getAll: (callback) => {
    db.query(`SELECT * FROM services ORDER BY created_at DESC`, callback);
  },

  getById: (id, callback) => {
    db.query(`SELECT * FROM services WHERE service_id = ?`, [id], callback);
  }
};

module.exports = Services;
