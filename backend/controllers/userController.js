// ============================
// backend/controllers/userController.js
// ============================

const bcrypt = require("bcryptjs");
const User = require("../models/userModel");
const db = require("../db");
const jwt = require("jsonwebtoken");

// ============================
//  تسجيل مستخدم جديد (Sign Up)
// ============================
exports.registerUser = async (req, res) => {
  try {
    const { full_name, email, password, role } = req.body;
    console.log("Role:", role, "Email:", email);

    if (!full_name || !email || !password)
      return res.status(400).json({ message: "All fields are required " });

    let student_id = null;

    if (role && role.toLowerCase() === "student") {
      const cleanEmail = email.trim().toLowerCase();
      if (cleanEmail.includes("@stu.najah.edu") && cleanEmail.startsWith("s")) {
        student_id = cleanEmail.slice(1, cleanEmail.indexOf("@"));
      } else {
        return res.status(400).json({
          message: "Please use your student email (@stu.najah.edu) ",
        });
      }
    } else if (
      role &&
      ["doctor", "admin"].includes(role.toLowerCase())
    ) {
      student_id = null;
    } else {
      return res.status(400).json({ message: "Invalid role " });
    }

    User.findByEmail(email, async (err, results) => {
      if (err) return res.status(500).json({ message: "Database error " });
      if (results.length > 0)
        return res.status(400).json({ message: "User already exists " });

      const hashedPassword = await bcrypt.hash(password, 10);

      User.create(
        full_name,
        student_id,
        email,
        hashedPassword,
        role,
        null,
        (err2) => {
          if (err2) {
            console.error(" MySQL Insert Error:", err2);
            return res
              .status(500)
              .json({ message: "Error registering user " });
          }

          if (role.toLowerCase() === "student") {
            const getUserIdSql = "SELECT id FROM users WHERE email = ?";
            db.query(getUserIdSql, [email], (err3, results3) => {
              if (err3 || results3.length === 0)
                return res.status(500).json({ message: "Failed to retrieve user ID" });

              const userId = results3[0].id;
              const insertStudentSql =
                "INSERT INTO students (student_id, user_id) VALUES (?, ?)";

              db.query(insertStudentSql, [student_id, userId], (err4) => {
                if (err4)
                  return res.status(500).json({ message: "Error saving student profile " });

                return res.status(201).json({
                  message: "Account created successfully ",
                  data: { full_name, student_id, email, role },
                });
              });
            });
            return;
          }

          if (role.toLowerCase() === "doctor") {
            const getUserIdSql = "SELECT id FROM users WHERE email = ?";
            db.query(getUserIdSql, [email], (err3, results3) => {
              if (err3 || results3.length === 0)
                return res.status(500).json({ message: "Failed to retrieve doctor ID" });

              const userId = results3[0].id;
              const insertDoctorSql =
                "INSERT INTO doctors (user_id, service_center_id) VALUES (?, 19)";

              db.query(insertDoctorSql, [userId], (err4) => {
                if (err4)
                  return res.status(500).json({ message: "Error saving doctor profile " });

                return res.status(201).json({
                  message: "Doctor account created successfully ",
                  data: { full_name, email, role, service_center_id: 19 },
                });
              });
            });
            return;
          }

          return res.status(201).json({
            message: "Account created successfully ",
            data: { full_name, email, role },
          });
        }
      );
    });
  } catch (error) {
    console.error("Unexpected error:", error);
    return res.status(500).json({ message: "Server error " });
  }
};

// ============================
// تسجيل الدخول (Sign In)
// ============================
exports.loginUser = async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password)
    return res.status(400).json({ message: "Please fill all fields " });

  try {
    User.findByEmail(email, async (err, results) => {
      if (err)
        return res.status(500).json({ message: "Database error " });

      if (results.length === 0)
        return res.status(404).json({ message: "User not found " });

      const user = results[0];
      let isMatch = false;

      if (user.password.startsWith("$2b$")) {
        isMatch = await bcrypt.compare(password, user.password);
      } else {
        isMatch = password === user.password;
      }

      if (!isMatch)
        return res.status(401).json({ message: "Incorrect password " });

      // ============================
      //  RBAC: جلب الصلاحيات من DB
      // ============================
      const [permRows] = await db.promise().query(`
        SELECT p.key_name
        FROM roles r
        JOIN role_permissions rp ON rp.role_id = r.id
        JOIN permissions p ON p.id = rp.permission_id
        WHERE r.name = ?
      `, [user.role]);

      const permissions = permRows.map(row => row.key_name);

      // ============================
      //  RBAC: إنشاء JWT مع الصلاحيات
      // ============================
      const token = jwt.sign(
        {
          id: user.id,
          email: user.email,
          role: user.role,
          permissions
        },
        process.env.JWT_SECRET || "uniserve_secret_key_2025",
        { expiresIn: process.env.JWT_EXPIRES_IN || "7d" }
      );

      delete user.password;

      let studentId = null;
      if (user.role === "student") {
        const [studentRow] = await db
          .promise()
          .query("SELECT student_id FROM students WHERE user_id = ?", [user.id]);

        if (studentRow.length > 0) {
          studentId = studentRow[0].student_id;
        }
      }

      return res.status(200).json({
        message: "Login successful ",
        token,
        user: {
          id: user.id,
          full_name: user.full_name,
          email: user.email,
          role: user.role,
          student_id: studentId,
        },
      });
    });
  } catch (error) {
    console.error("Unexpected error during login:", error);
    return res.status(500).json({ message: "Server error " });
  }
};

// ============================
//  إعادة تعيين كلمة المرور
// ============================
exports.resetPassword = async (req, res) => {
  const { email, code, newPassword } = req.body;

  if (!email || !code || !newPassword)
    return res.status(400).json({ message: "Please provide email, code, and new password" });

  const sql = "SELECT reset_token, reset_expires FROM users WHERE email = ?";
  db.query(sql, [email], async (err, results) => {
    if (err) return res.status(500).json({ message: "Database error " });
    if (results.length === 0)
      return res.status(404).json({ message: "User not found " });

    const user = results[0];

    if (!user.reset_token || !user.reset_expires)
      return res.status(400).json({ message: "No reset request found." });

    if (new Date() > new Date(user.reset_expires))
      return res.status(400).json({ message: "Verification code expired." });

    if (user.reset_token !== code)
      return res.status(400).json({ message: "Invalid verification code " });

    const hashed = await bcrypt.hash(newPassword, 10);
    const updateSql =
      "UPDATE users SET password = ?, reset_token = NULL, reset_expires = NULL WHERE email = ?";
    db.query(updateSql, [hashed, email], (updateErr) => {
      if (updateErr)
        return res.status(500).json({ message: "Failed to update password " });

      return res.status(200).json({ message: "Password reset successful " });
    });
  });
};

// ============================
//  جلب كل المستخدمين
// ============================
exports.getAllUsers = (req, res) => {
  const query = `
    SELECT id, full_name, email, photo_url, role
    FROM users
    ORDER BY full_name ASC
  `;

  db.query(query, (err, results) => {
    if (err)
      return res.status(500).json({ message: "Server error while fetching users " });

    return res.status(200).json(results);
  });
};
