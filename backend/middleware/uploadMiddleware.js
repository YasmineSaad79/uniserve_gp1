// ============================
// 📁 backend/middleware/uploadMiddleware.js
// ============================

const multer = require("multer");
const path = require("path");
const fs = require("fs");

// 🔹 مكان حفظ الصور
const uploadDir = path.join(__dirname, "../uploads");

// إنشاء المجلد إذا لم يكن موجود
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir);
}

// 🔹 إعداد التخزين
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    const uniqueName = Date.now() + "-" + Math.round(Math.random() * 1e9) + ext;
    cb(null, uniqueName);
  },
});

// 🔹 فلترة الملفات
const fileFilter = (req, file, cb) => {
  const allowedExtensions = [".jpg", ".jpeg", ".png", ".gif", ".webp"];
  const fileExt = path.extname(file.originalname).toLowerCase();

  // ✅ قبول إذا الامتداد صحيح أو MIME type يبدأ بـ "image/"
  if (allowedExtensions.includes(fileExt) || file.mimetype.startsWith("image/")) {
    cb(null, true);
  } else {
    cb(new Error("Only image files are allowed!"), false);
  }
};

// 🔹 تصدير middleware
const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5 ميجابايت كحد أقصى
});

module.exports = upload;
