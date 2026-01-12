// ============================
// backend/controllers/userController.js
// ============================

const bcrypt = require("bcryptjs");
const User = require("../models/userModel");
const db = require("../db");
const jwt = require("jsonwebtoken");
const fs = require("fs");
const path = require("path");

// ============================
//  Allowed files paths
// ============================
const allowedStudentsPath = path.join(
  __dirname,
  "../data/allowed_students.json"
);

const allowedDoctorsPath = path.join(
  __dirname,
  "../data/allowed_doctors.json"
);

// ============================
//  Helpers
// ============================
function isEmailAllowedFromFile(filePath, email) {
  if (!fs.existsSync(filePath)) return false;

  const data = JSON.parse(fs.readFileSync(filePath, "utf8"));
  const allowedEmails = data.allowedEmails || [];

  return allowedEmails.includes(email.toLowerCase());
}

// ============================
//  تسجيل مستخدم جديد (Sign Up)
// ============================
exports.registerUser = async (req, res) => {
  try {
    const { full_name, email, password, role } = req.body;

    if (!full_name || !email || !password || !role) {
      return res.status(400).json({ message: "All fields are required" });
    }

    let student_id = null;
    const cleanEmail = email.trim().toLowerCase();

    // ============================
    // STUDENT
    // ============================
    if (role.toLowerCase() === "student") {
      if (!isEmailAllowedFromFile(allowedStudentsPath, cleanEmail)) {
        return res.status(403).json({
          message:
            "You are not enrolled in this course. Please contact the service center.",
        });
      }

      if (
        cleanEmail.startsWith("s") &&
        cleanEmail.endsWith("@stu.najah.edu")
      ) {
        student_id = cleanEmail.slice(1, cleanEmail.indexOf("@"));
      } else {
        return res.status(400).json({
          message: "Please use your student email (@stu.najah.edu)",
        });
      }
    }

    // ============================
    // DOCTOR
    // ============================
    else if (role.toLowerCase() === "doctor") {
      if (!isEmailAllowedFromFile(allowedDoctorsPath, cleanEmail)) {
        return res.status(403).json({
          message:
            "You are not authorized to register as a doctor. Please contact the administrator.",
        });
      }

      student_id = null;
    }

    // ============================
    // ADMIN
    // ============================
    else if (role.toLowerCase() === "admin") {
      student_id = null;
    }

    else {
      return res.status(400).json({ message: "Invalid role" });
    }

    // ============================
    // Check existing user
    // ============================
    User.findByEmail(cleanEmail, async (err, results) => {
      if (err)
        return res.status(500).json({ message: "Database error" });

      if (results.length > 0)
        return res.status(400).json({ message: "User already exists" });

      const hashedPassword = await bcrypt.hash(password, 10);

      User.create(
        full_name,
        student_id,
        cleanEmail,
        hashedPassword,
        role,
        null,
        async (err2) => {
          if (err2) {
            console.error(err2);
            return res
              .status(500)
              .json({ message: "Error registering user" });
          }

          const [userRows] = await db
            .promise()
            .query("SELECT id FROM users WHERE email = ?", [cleanEmail]);

          const userId = userRows[0].id;

          // ============================
          // Insert student
          // ============================
          if (role.toLowerCase() === "student") {
            await db
              .promise()
              .query(
                "INSERT INTO students (student_id, user_id) VALUES (?, ?)",
                [student_id, userId]
              );
          }

          // ============================
          // Insert doctor
          // ============================
          if (role.toLowerCase() === "doctor") {
            await db
              .promise()
              .query(
                "INSERT INTO doctors (user_id, service_center_id) VALUES (?, ?)",
                [userId, 19]
              );
          }

          return res.status(201).json({
            message: "Account created successfully",
            data: { full_name, student_id, email: cleanEmail, role },
          });
        }
      );
    });
  } catch (error) {
    console.error(error);
    return res.status(500).json({ message: "Server error" });
  }
};

// ============================
// تسجيل الدخول (Sign In)
// ============================
exports.loginUser = async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password)
    return res.status(400).json({ message: "Please fill all fields" });

  try {
    const [rows] = await db.promise().query(
      `
      SELECT 
        u.id,
        u.full_name,
        u.email,
        u.password,
        u.role_id,
        u.is_active,
        r.name AS role
      FROM users u
      JOIN roles r ON u.role_id = r.id
      WHERE u.email = ?
      `,
      [email]
    );

    if (rows.length === 0)
      return res.status(404).json({ message: "User not found" });

    const user = rows[0];

    if (user.is_active === 0) {
      return res.status(403).json({
        message:
          "Your account has been deactivated. Please contact the administrator.",
      });
    }

    const isMatch = user.password.startsWith("$2b$")
      ? await bcrypt.compare(password, user.password)
      : password === user.password;

    if (!isMatch)
      return res.status(401).json({ message: "Incorrect password" });

    // ============================
    // Permissions (RBAC)
    // ============================
    const [permRows] = await db.promise().query(
      `
      SELECT p.key_name
      FROM role_permissions rp
      JOIN permissions p ON p.id = rp.permission_id
      WHERE rp.role_id = ?
      `,
      [user.role_id]
    );

    const permissions = permRows.map((row) => row.key_name);

    const token = jwt.sign(
      {
        id: user.id,
        email: user.email,
        role: user.role,
        roleId: user.role_id,
        permissions,
      },
      process.env.JWT_SECRET || "uniserve_secret_key_2025",
      { expiresIn: "7d" }
    );

    let studentId = null;
    if (user.role === "student") {
      const [studentRow] = await db
        .promise()
        .query(
          "SELECT student_id FROM students WHERE user_id = ?",
          [user.id]
        );

      if (studentRow.length > 0) {
        studentId = studentRow[0].student_id;
      }
    }

    return res.status(200).json({
      message: "Login successful",
      token,
      user: {
        id: user.id,
        full_name: user.full_name,
        email: user.email,
        role: user.role,
        student_id: studentId,
      },
    });
  } catch (error) {
    console.error("Login error:", error);
    return res.status(500).json({ message: "Server error" });
  }
};

// ============================
//  إعادة تعيين كلمة المرور
// ============================
exports.resetPassword = async (req, res) => {
  const { email, code, newPassword } = req.body;

  if (!email || !code || !newPassword)
    return res.status(400).json({ message: "Missing fields" });

  const sql = "SELECT reset_token, reset_expires FROM users WHERE email = ?";
  db.query(sql, [email], async (err, results) => {
    if (err) return res.status(500).json({ message: "Database error" });
    if (results.length === 0)
      return res.status(404).json({ message: "User not found" });

    const user = results[0];

    if (
      !user.reset_token ||
      !user.reset_expires ||
      new Date() > new Date(user.reset_expires) ||
      user.reset_token !== code
    ) {
      return res.status(400).json({ message: "Invalid or expired code" });
    }

    const hashed = await bcrypt.hash(newPassword, 10);
    const updateSql =
      "UPDATE users SET password = ?, reset_token = NULL, reset_expires = NULL WHERE email = ?";
    db.query(updateSql, [hashed, email], () =>
      res.status(200).json({ message: "Password reset successful" })
    );
  });
};

// ============================
//  جلب كل المستخدمين (Admin)
// ============================
exports.getAllUsers = (req, res) => {
  const query = `
    SELECT 
      u.id,
      u.full_name,
      u.email,
      u.photo_url,
      r.name AS role
    FROM users u
    JOIN roles r ON u.role_id = r.id
    ORDER BY u.full_name ASC
  `;

  db.query(query, (err, results) => {
    if (err)
      return res
        .status(500)
        .json({ message: "Server error while fetching users" });

    return res.status(200).json(results);
  });
};
