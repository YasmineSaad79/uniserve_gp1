// ============================
//  backend/routes/userRoutes.js
// ============================

const express = require("express");
const router = express.Router();
const userController = require("../controllers/userController");
const crypto = require("crypto");
const nodemailer = require("nodemailer");
const db = require("../db");

const verifyToken = require("../middleware/verifyToken");
const authorizePermission = require("../middleware/authorizePermission");

// ============================
//  إعداد الـ SMTP
// ============================
const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST || "smtp.gmail.com",
  port: Number(process.env.SMTP_PORT || 465),
  secure: (process.env.SMTP_SECURE || "true") === "true",
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

// ============================
//  تسجيل مستخدم جديد (Public)
// ============================
router.post("/signup", userController.registerUser);

// ============================
//  تسجيل الدخول (Public)
// ============================
router.post("/signIn", userController.loginUser);

// ============================
//  نسيان كلمة المرور (Public)
// ============================
router.post("/forgot-password", (req, res) => {
  const { email } = req.body;
  if (!email) return res.status(400).json({ message: "Email is required" });

  const token = crypto.randomBytes(3).toString("hex").toUpperCase();
  const expires = new Date(Date.now() + 15 * 60 * 1000);

  const sql =
    "UPDATE users SET reset_token = ?, reset_expires = ? WHERE email = ?";
  db.query(sql, [token, expires, email], (err, result) => {
    if (err) {
      console.error(err);
      return res.status(500).json({ message: "Database error" });
    }
    if (result.affectedRows === 0)
      return res.status(404).json({ message: "User not found" });

    const mailOptions = {
      from: process.env.FROM_EMAIL || `"UniServe" <${process.env.SMTP_USER}>`,
      to: email,
      subject: "UniServe Password Reset Code",
      html: `
        <h3>UniServe Password Reset</h3>
        <h2>${token}</h2>
        <p>Valid for 15 minutes</p>
      `,
    };

    transporter.sendMail(mailOptions, () =>
      res.json({ message: "Verification code sent " })
    );
  });
});

// ============================
//  إعادة تعيين كلمة المرور (Public)
// ============================
router.post("/reset-password", userController.resetPassword);

// ============================
//  جلب كل المستخدمين
//  Permission: canViewStudents
// ============================
router.get(
  "/",
  verifyToken,
  authorizePermission("canViewStudents"),
  userController.getAllUsers
);

// ============================
//  جلب بروفايل مستخدم
//  Permission: canViewProfile
// ============================
router.get(
  "/profile/:id",
  verifyToken,
  authorizePermission("canViewProfile"),
  async (req, res) => {
    const { id } = req.params;
    const sql = "SELECT full_name, email, photo_url FROM users WHERE id = ?";
    db.query(sql, [id], (err, results) => {
      if (err) return res.status(500).json({ message: "Database error" });
      if (results.length === 0)
        return res.status(404).json({ message: "User not found" });

      res.json(results[0]);
    });
  }
);

// ============================
//  Get user_id by student_id
//  Permission: canViewProfile
// ============================
router.get(
  "/get-userid-by-uni/:studentId",
  verifyToken,
  authorizePermission("canViewProfile"),
  async (req, res) => {
    const { studentId } = req.params;

    const [rows] = await db
      .promise()
      .query("SELECT id FROM users WHERE student_id = ?", [studentId]);

    if (rows.length === 0)
      return res.status(404).json({ message: "Student not found" });

    res.json({ user_id: rows[0].id });
  }
);

// ============================
//  Debug
// ============================
router.get("/debug/me", verifyToken, (req, res) => {
  res.json({ user: req.user });
});

module.exports = router;
