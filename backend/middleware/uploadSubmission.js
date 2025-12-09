const multer = require("multer");
const path = require("path");

// Folder: /uploads/submissions
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, "uploads/submissions/");
  },
  filename: function (req, file, cb) {
    const uniqueName =
      Date.now() + "-" + Math.round(Math.random() * 1e9) + ".pdf";
    cb(null, uniqueName);
  },
});

function fileFilter(req, file, cb) {
  const ext = path.extname(file.originalname).toLowerCase();

  // 1) لو الـ mimetype صحيح (application/pdf)
  const isPdfMime = file.mimetype === "application/pdf";

  // 2) لو الامتداد PDF حتى لو mime غلط
  const isPdfExt = ext === ".pdf";

  if (isPdfMime || isPdfExt) {
    cb(null, true);
  } else {
    cb(new Error("Only PDF files are allowed"), false);
  }
}


const uploadSubmission = multer({
  storage,
  fileFilter,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB max
});

module.exports = uploadSubmission;
