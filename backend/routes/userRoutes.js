// ============================
// 📁 backend/routes/userRoutes.js
// ============================

const express = require("express");
const router = express.Router();
const userController = require("../controllers/userController");
const bcrypt = require("bcryptjs");
const crypto = require("crypto");
const nodemailer = require("nodemailer");
const db = require("../db");
const verifyToken = require("../middleware/verifyToken");   // ✅ هذا السطر لازم
const authorizePermission = require("../middleware/authorizePermission");


// ============================
// ✉️ إعداد الـ SMTP
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
// 🟢 تسجيل مستخدم جديد (Sign Up)
// ============================
router.post("/signup", userController.registerUser);
router.get("/", userController.getAllUsers);

// ============================
// 🟣 تسجيل الدخول (Sign In)
// ============================
router.post("/signIn", userController.loginUser);

// ============================
// 🔐 نسيان كلمة المرور (Forgot Password)
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
      return res
        .status(404)
        .json({ message: "User with this email not found" });

    const mailOptions = {
      from: process.env.FROM_EMAIL || `"UniServe" <${process.env.SMTP_USER}>`,
      to: email,
      subject: "UniServe Password Reset Code",
      html: `
        <h3>UniServe Password Reset</h3>
        <p>Your password reset code is:</p>
        <h2 style="letter-spacing:3px;">${token}</h2>
        <p>This code is valid for <b>15 minutes</b>.</p>
      `,
    };

    transporter.sendMail(mailOptions, (mailErr, info) => {
      if (mailErr) {
        console.error("Mail error:", mailErr);
        return res.status(500).json({ message: "Failed to send email" });
      }
      console.log("✅ Reset code sent:", info.response);
      return res
        .status(200)
        .json({ message: "Verification code sent to your email ✅" });
    });
  });
});

// ============================
// 🔁 إعادة تعيين كلمة المرور (Reset Password)
// ============================
router.post("/reset-password", userController.resetPassword);

// GET بيانات المستخدم حسب الـ email أو الـ id
router.get("/profile/:id", (req, res) => {
  const { id } = req.params;
  const sql = "SELECT full_name, email, photo_url FROM users WHERE id = ?";
  db.query(sql, [id], (err, results) => {
    if (err) return res.status(500).json({ message: "Database error" });
    if (results.length === 0)
      return res.status(404).json({ message: "User not found" });

    const user = results[0];
    return res.json({
      fullName: user.full_name,
      email: user.email,
      photo_url: user.photo_url 
    });
  });
});


module.exports = router;
