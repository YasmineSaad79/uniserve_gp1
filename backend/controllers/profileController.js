const User = require("../models/userModel");
const db = require("../db");

// جلب بيانات المستخدم حسب الـ ID
exports.getProfileById = (req, res) => {
  const userId = req.params.id;

  const query = `
    SELECT u.full_name, u.email, u.photo_url, s.student_id
    FROM users u
    LEFT JOIN students s ON u.id = s.user_id
    WHERE u.id = ?
  `;

  db.query(query, [userId], (err, results) => {
    if (err) {
      console.error(" Database error:", err);
      return res.status(500).json({ message: "Database error" });
    }

    if (results.length === 0) {
      return res.status(404).json({ message: "User not found" });
    }

    res.json(results[0]);
  });
};


// تحديث صورة المستخدم
exports.updatePhoto = (req, res) => {
  const email = req.body.email;

  if (!req.file) {
    return res.status(400).json({ message: "No photo uploaded" });
  }

  const photoUrl = `/uploads/${req.file.filename}`;

  User.updatePhoto(email, photoUrl, (err, result) => {
    if (err) {
      console.error(err);
      return res.status(500).json({ message: "Error updating photo" });
    }

    res.json({
      message: "Photo updated successfully",
      photo_url: photoUrl,
    });
  });
};
