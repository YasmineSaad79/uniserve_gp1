// controllers/serviceController.js
const db = require("../db");

exports.getCenterStudents = async (req, res) => {
  try {
    const centerUserId = req.user.id; // مستخدم المركز نفسه (من JWT)

    // 1 نجيب center_id من جدول center حسب user_id
    const [centerRows] = await db
      .promise()
      .query("SELECT center_id FROM center WHERE user_id = ?", [
        centerUserId,
      ]);

    if (!centerRows.length) {
      return res.status(404).json({
        message: "Center not found for this user",
      });
    }

    const centerId = centerRows[0].center_id;

    // 2 نجيب الطلاب اللي مرتبطين بهذا المركز من جدول students
    const sql = `
      SELECT 
        u.id,
        u.full_name,
        u.email,
        u.photo_url
      FROM users u
      JOIN students s ON u.id = s.user_id
      WHERE s.center_id = ?
    `;

    const [rows] = await db.promise().query(sql, [centerId]);

    return res.json(rows);
  } catch (err) {
    console.error(" getCenterStudents:", err);
    return res.status(500).json({
      message: "Internal server error",
    });
  }
};
