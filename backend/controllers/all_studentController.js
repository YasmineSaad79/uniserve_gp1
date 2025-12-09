// 📁 backend/controllers/serviceController.js
const db = require("../db");

exports.getStudentsForService = (req, res) => {
  try {
    const sql = `
      SELECT 
        u.id, 
        u.full_name, 
        u.email, 
        u.photo_url, 
        s.student_id
      FROM users u
      JOIN students s ON u.id = s.user_id
      WHERE u.role = 'student'
      ORDER BY u.full_name ASC
    `;

    db.query(sql, (err, results) => {
      if (err) {
        console.error("❌ Error fetching students for service:", err);
        return res.status(500).json({ message: "Database error" });
      }

      res.status(200).json({
        success: true,
        message: "✅ Students fetched successfully",
        data: results,
      });
    });
  } catch (err) {
    console.error("❌ getStudentsForService Exception:", err);
    return res.status(500).json({ message: "Internal server error" });
  }
};
