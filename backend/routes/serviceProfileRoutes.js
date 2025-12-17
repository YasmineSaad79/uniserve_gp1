const express = require("express");
const router = express.Router();

const verifyToken = require("../middleware/verifyToken");
const authorizePermission = require("../middleware/authorizePermission");
const upload = require("../middleware/uploadMiddleware");
const db = require("../db");

//  Logger 
const logRequest = (req, res, next) => {
  console.log(` [${req.method}] Request to /api/service${req.path}`);
  next();
};

// ======================================================
//  جلب بيانات المركز الخدمي
//  Permission: canViewProfile
// ======================================================
router.get(
  "/profile",
  verifyToken,
  authorizePermission("canViewProfile"),
  logRequest,
  (req, res) => {
    const userId = req.user.id;

    const sql = `
      SELECT id, full_name, email, photo_url, role
      FROM users
      WHERE id = ? AND role = 'service_center'
    `;

    db.query(sql, [userId], (err, results) => {
      if (err) {
        console.error(" Database error:", err);
        return res.status(500).json({ message: "Database error" });
      }

      if (results.length === 0) {
        return res.status(404).json({ message: "Service center not found" });
      }

      res.json({
        message: " Service profile fetched successfully",
        profile: results[0],
      });
    });
  }
);

// ======================================================
//  تحديث بيانات المركز الخدمي
//  Permission: canEditProfile
// ======================================================
router.put(
  "/profile",
  verifyToken,
  authorizePermission("canEditProfile"),
  upload.single("photo"),
  logRequest,
  (req, res) => {
    const userId = req.user.id;
    const { full_name, email } = req.body;

    if (!full_name && !email && !req.file) {
      return res.status(400).json({ message: "No data provided for update" });
    }

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

    if (req.file) {
      const photoPath = `/uploads/${req.file.filename}`;
      updates.push("photo_url = ?");
      params.push(photoPath);
    }

    const sql = `
      UPDATE users
      SET ${updates.join(", ")}
      WHERE id = ? AND role = 'service_center'
    `;

    params.push(userId);

    db.query(sql, params, (err, result) => {
      if (err) {
        console.error(" Database error:", err);
        return res.status(500).json({ message: "Database error" });
      }

      if (result.affectedRows === 0) {
        return res.status(404).json({ message: "Service center not found" });
      }

      res.json({
        message: " Profile updated successfully",
      });
    });
  }
);

module.exports = router;
