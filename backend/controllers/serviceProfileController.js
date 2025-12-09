const db = require("../db");
const { verifyToken } = require("../middleware/verifyToken.js");

// ✅ جلب بيانات المركز الخدمي باستخدام التوكن
exports.getServiceProfile = (req, res) => {
  const userId = req.user.id; // من التوكن

const sql = `
 SELECT 
  u.id AS user_id, 
  u.full_name, 
  u.email, 
  u.photo_url, 
  u.role,
  c.center_id AS service_center_id
FROM users u
LEFT JOIN center c ON u.id = c.user_id
WHERE u.id = ? AND u.role = 'service_center'

`;


  db.query(sql, [userId], (err, results) => {
    if (err) {
      console.error("❌ Database error:", err);
      return res.status(500).json({ message: "Database error" });
    }

    if (results.length === 0) {
      res.json({
  user_id: results[0].user_id,
  service_center_id: results[0].service_center_id,
  full_name: results[0].full_name,
  email: results[0].email,
  photo_url: results[0].photo_url,
  role: results[0].role,
});

      return res.status(404).json({ message: "Service user not found" });
    }

    res.json(results[0]);
  });
};
const path = require("path");
const fs = require("fs");

// ✅ تحديث بيانات المركز الخدمي (الاسم + الإيميل + الصورة)
exports.updateServiceProfile = (req, res) => {
  const userId = req.user.id; // من التوكن
  const { full_name, email } = req.body;

  if (!full_name && !email && !req.files?.photo) {
    return res.status(400).json({ message: "No data provided for update" });
  }

  // 📸 في حال تم رفع صورة جديدة
  let photoPath = null;
  if (req.files && req.files.photo && req.files.photo.length > 0) {
    const uploadedFile = req.files.photo[0];
    photoPath = `/uploads/${uploadedFile.filename}`;
  }

  // 📦 نبني استعلام التحديث ديناميكيًا
  const updates = [];
  const params = [];

  if (full_name) {
    updates.push("full_name = ?");
    params.push(full_name);
  }
  if (email) {
    updates.push("email = ?");
    params.push(email);
  }
  if (photoPath) {
    updates.push("photo_url = ?");
    params.push(photoPath);
  }

  const sql = `UPDATE users SET ${updates.join(", ")} WHERE id = ? AND role = 'service_center'`;
  params.push(userId);

  db.query(sql, params, (err, result) => {
    if (err) {
      console.error("❌ Error updating service profile:", err);
      return res.status(500).json({ message: "Database update error" });
    }

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Service user not found" });
    }

    res.status(200).json({
      message: "Profile updated successfully ✅",
      photo_url: photoPath,
    });
  });
};
