const express = require("express");
const router = express.Router();

const verifyToken = require("../middleware/verifyToken");
const authorizePermission = require("../middleware/authorizePermission");
const db = require("../db");

// 🧾 لوج لأي طلب يتم على الراوت (اختياري)
const logRequest = (req, res, next) => {
  console.log(`🟢 [${req.method}] Request to /api/service${req.path}`);
  next();
};

// ======================================================
// 🟣 جلب بيانات المركز الخدمي (صلاحية: canViewProfile)
// ======================================================
router.get(
  "/profile",
  verifyToken,
  authorizePermission("canViewProfile"),
  logRequest,
  (req, res) => {
    const userId = req.user.id; // من التوكن

    const sql = `
  SELECT id, full_name, email, photo_url, role
  FROM users
  WHERE id = ? AND role = 'service_center'
`;

    db.query(sql, [userId], (err, results) => {

      if (err) {
        console.error("❌ Database error:", err);
        return res.status(500).json({ message: "Database error" });
      }

      if (results.length === 0) {
        return res.status(404).json({ message: "Service user not found" });
      }

      res.json({
        message: "✅ Service profile fetched successfully",
        profile: results[0],
      });
    });
  }
);
// ======================================================
// 🟢 تحديث بيانات المركز الخدمي (صلاحية: canEditProfile)
// ======================================================
const multer = require("multer");
const path = require("path");

// إعداد multer لرفع الصور
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, "uploads/"),
  filename: (req, file, cb) =>
    cb(
      null,
      Date.now() + "-" + Math.round(Math.random() * 1e9) + path.extname(file.originalname)
    ),
});

const upload = multer({ storage });

router.put(
  "/profile",
  verifyToken,
  authorizePermission("canEditProfile"),
  upload.fields([{ name: "photo", maxCount: 1 }]),
  logRequest,
  (req, res) => {
    const userId = req.user.id;
    const { full_name, email } = req.body;
console.log("📦 req.body:", req.body);
console.log("📸 req.files:", req.files);

    if (!full_name && !email && !req.files?.photo) {
      return res.status(400).json({ message: "No data provided for update" });
    }

    // 📸 في حال تم رفع صورة جديدة
    let photoPath = null;
    if (req.files && req.files.photo && req.files.photo.length > 0) {
      const uploadedFile = req.files.photo[0];
      photoPath = `/uploads/${uploadedFile.filename}`;
    }

    // بناء استعلام التحديث
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

   const sql = `
  UPDATE users 
  SET ${updates.join(", ")} 
  WHERE id = ? AND (role = 'service' OR role = 'service_center')
`;
params.push(userId);

// 🟣 Debug
console.log("🧩 SQL Query:", sql);
console.log("🧠 Params:", params);

db.query(sql, params, (err, result) => {
  if (err) {
    console.error("❌ Database error details:", err);
    return res.status(500).json({ message: "Database error", error: err });
  }

  if (result.affectedRows === 0) {
    console.warn("⚠️ No rows updated. Check user role or ID!");
    return res.status(404).json({ message: "Service user not found or role mismatch" });
  }

  res.status(200).json({
    message: "✅ Profile updated successfully",
    photo_url: photoPath,
  });
});

  }
);

module.exports = router;
