// ============================
// 📁 backend/models/userModel.js
// ============================

const db = require("../db");

const User = {
  // ✅ إنشاء مستخدم جديد
  // يمكن إرسال photo_url أو تركه فارغ (null)
  create: (full_name, student_id, email, password, role, photo_url = null, callback) => {
    const query = `
      INSERT INTO users (full_name, student_id, email, password, role, photo_url, created_at)
      VALUES (?, ?, ?, ?, ?, ?, NOW())
    `;
    db.query(query, [full_name, student_id, email, password, role, photo_url], callback);
  },

  // ✅ البحث عن مستخدم حسب الإيميل
  findByEmail: (email, callback) => {
    const query = "SELECT * FROM users WHERE email = ?";
    db.query(query, [email], callback);
  },

  // ✅ تحديث رابط الصورة للمستخدم
  updatePhoto: (email, photo_url, callback) => {
    const query = "UPDATE users SET photo_url = ? WHERE email = ?";
    db.query(query, [photo_url, email], callback);
  },
};

module.exports = User;
