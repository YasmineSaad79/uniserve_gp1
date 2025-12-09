// file: backend/middleware/upload.js
const multer = require('multer');
const path = require('path');
const fs = require('fs');

// تأكد من وجود مجلد uploads
const uploadDir = path.join(__dirname, '../uploads');
if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir, { recursive: true });
}

// 1️⃣ إعداد تخزين الملفات
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, uploadDir); // مجلد الحفظ
    },
    filename: (req, file, cb) => {
        const ext = path.extname(file.originalname); // الامتداد
        const name = path.basename(file.originalname, ext).replace(/\s+/g, '_'); // إزالة الفراغات
        cb(null, Date.now() + '-' + name + ext);
    }
});

// 2️⃣ فلتر الملفات المسموحة
const fileFilter = (req, file, cb) => {
    const allowedMimeTypes = [
        'image/jpeg', 'image/jpg', 'image/png', 'image/gif',
        'image/webp', 'image/heic', 'image/heif', 'application/octet-stream'
    ];

    if (allowedMimeTypes.includes(file.mimetype)) {
        cb(null, true);
    } else {
        cb(new Error('Only image files are allowed (jpeg, jpg, png, gif, webp, heic, heif).'), false);
    }
};

// 3️⃣ إنشاء كائن multer
const upload = multer({
    storage,
    limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
    fileFilter
});

// ✅ تصديره بشكل يسمح باستخدام `.single(...)` لاحقًا
module.exports = upload;
