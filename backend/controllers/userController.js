// ============================
// 📁 backend/controllers/userController.js
// ============================

const bcrypt = require("bcryptjs");
const User = require("../models/userModel");
const db = require("../db");
const jwt = require("jsonwebtoken");

// ============================
// 🟢 تسجيل مستخدم جديد (Sign Up)
// ============================
exports.registerUser = async (req, res) => {
  try {
    const { full_name, email, password, role } = req.body;
    console.log("Role:", role, "Email:", email);

    if (!full_name || !email || !password)
      return res.status(400).json({ message: "All fields are required ❌" });

    // ============================
    // استخراج student_id فقط للطلاب
    // ============================
    let student_id = null;

    if (role && role.toLowerCase() === "student") {
      const cleanEmail = email.trim().toLowerCase();
      if (cleanEmail.includes("@stu.najah.edu") && cleanEmail.startsWith("s")) {
        student_id = cleanEmail.slice(1, cleanEmail.indexOf("@"));
      } else {
        return res.status(400).json({
          message: "Please use your student email (@stu.najah.edu) ❌",
        });
      }
    } else if (role && role.toLowerCase() === "doctor") {
      student_id = null;
    } else if (role && role.toLowerCase() === "admin") {
      student_id = null;
    } else {
      return res.status(400).json({ message: "Invalid role ❌" });
    }

    // ============================
    // التحقق من وجود المستخدم
    // ============================
    User.findByEmail(email, async (err, results) => {
      if (err) return res.status(500).json({ message: "Database error ❌" });

      if (results.length > 0)
        return res.status(400).json({ message: "User already exists ❌" });

      // ============================
      // تشفير كلمة المرور
      // ============================
      const hashedPassword = await bcrypt.hash(password, 10);

      // ============================
      // إنشاء المستخدم في جدول users
      // ============================
      User.create(
        full_name,
        student_id,
        email,
        hashedPassword,
        role,
        null, // photo_url
        (err2) => {
          if (err2) {
            console.error("❌ MySQL Insert Error:", err2);
            return res
              .status(500)
              .json({ message: "Error registering user ❌" });
          }

          // ==============================================================================
          // 🟢 إذا كان طالب → أضفه في جدول students
          // ==============================================================================
          if (role.toLowerCase() === "student") {
            const getUserIdSql = "SELECT id FROM users WHERE email = ?";

            db.query(getUserIdSql, [email], (err3, results3) => {
              if (err3 || results3.length === 0) {
                console.error("❌ Error getting user ID:", err3);
                return res
                  .status(500)
                  .json({ message: "Failed to retrieve user ID" });
              }

              const userId = results3[0].id;

              const insertStudentSql = `
                INSERT INTO students (student_id, user_id)
                VALUES (?, ?)`;

              db.query(insertStudentSql, [student_id, userId], (err4) => {
                if (err4) {
                  console.error(
                    "❌ Failed to insert into students table:",
                    err4
                  );
                  return res.status(500).json({
                    message: "Error saving student profile ❌",
                  });
                }

                return res.status(201).json({
                  message: "Account created successfully ✅",
                  data: { full_name, student_id, email, role },
                });
              });
            });

            return; // مهم جداً
          }

          // ==============================================================================
          // 🟣 إذا كان دكتور → أضفه تلقائياً في جدول doctors مع service_center_id = 19
          // ==============================================================================
          if (role.toLowerCase() === "doctor") {
            const getUserIdSql = "SELECT id FROM users WHERE email = ?";

            db.query(getUserIdSql, [email], (err3, results3) => {
              if (err3 || results3.length === 0) {
                console.error("❌ Error getting doctor user ID:", err3);
                return res
                  .status(500)
                  .json({ message: "Failed to retrieve doctor ID" });
              }

              const userId = results3[0].id;

              // 🟣 إضافة الدكتور لجدول doctors تلقائياً
              const insertDoctorSql = `
                INSERT INTO doctors (user_id, service_center_id)
                VALUES (?, 19)
              `;

              db.query(insertDoctorSql, [userId], (err4) => {
                if (err4) {
                  console.error(
                    "❌ Failed to insert into doctors table:",
                    err4
                  );
                  return res
                    .status(500)
                    .json({ message: "Error saving doctor profile ❌" });
                }

                return res.status(201).json({
                  message: "Doctor account created successfully ✅",
                  data: {
                    full_name,
                    email,
                    role,
                    service_center_id: 19,
                  },
                });
              });
            });

            return;
          }

          // ==============================================================================
          // غير طالب وغير دكتور (مثل admin)
          // ==============================================================================
          return res.status(201).json({
            message: "Account created successfully ✅",
            data: { full_name, email, role },
          });
        }
      );
    });
  } catch (error) {
    console.error("Unexpected error:", error);
    return res.status(500).json({ message: "Server error ❌" });
  }
};

// ============================
// 🟣 تسجيل الدخول (Sign In)
// ============================
exports.loginUser = async (req, res) => {
  const { email, password } = req.body;

  // ✅ تحقق من الحقول
  if (!email || !password)
    return res.status(400).json({ message: "Please fill all fields ❌" });

  try {
    // ✅ البحث عن المستخدم في قاعدة البيانات
    User.findByEmail(email, async (err, results) => {
      if (err) {
        console.error("Database error:", err);
        return res.status(500).json({ message: "Database error ❌" });
      }

      if (results.length === 0)
        return res.status(404).json({ message: "User not found ❌" });

      const user = results[0];
      let isMatch = false;

      // ✅ مقارنة كلمة المرور (مشفرة أو نصية)
      if (user.password.startsWith("$2b$")) {
        isMatch = await bcrypt.compare(password, user.password);
      } else {
        isMatch = password === user.password;
      }

      if (!isMatch)
        return res.status(401).json({ message: "Incorrect password ❌" });

      // ✅ إنشاء JWT Token
      const token = jwt.sign(
        {
          id: user.id,
          email: user.email,
          role: user.role,
        },
        process.env.JWT_SECRET || "uniserve_secret_key_2025", // المفتاح السري
        { expiresIn: process.env.JWT_EXPIRES_IN || "7d" } // صلاحية 7 أيام
      );

      // ✅ إزالة كلمة المرور من النتائج قبل الإرسال
      delete user.password;

      // ✅ إرجاع الرد الكامل مع التوكن
     // ✅ جلب student_id في حال كان المستخدم طالب
let studentId = null;
if (user.role === "student") {
  const [studentRow] = await db
    .promise()
    .query("SELECT student_id FROM students WHERE user_id = ?", [user.id]);

  if (studentRow.length > 0) {
    studentId = studentRow[0].student_id;
  }
}

// ✅ إرجاع الرد الكامل مع التوكن والـ student_id
return res.status(200).json({
  message: "Login successful ✅",
  token,
  user: {
    id: user.id,
    full_name: user.full_name,
    email: user.email,
    role: user.role,
    student_id: studentId, // 🟢 تمت الإضافة هنا
  },
});

    });
  } catch (error) {
    console.error("Unexpected error during login:", error);
    return res.status(500).json({ message: "Server error ❌" });
  }
};


// ============================
// 🔁 إعادة تعيين كلمة المرور (Reset Password)
// ============================
exports.resetPassword = async (req, res) => {
  const { email, code, newPassword } = req.body;

  if (!email || !code || !newPassword)
    return res
      .status(400)
      .json({ message: "Please provide email, code, and new password" });

  const sql = "SELECT reset_token, reset_expires FROM users WHERE email = ?";
  db.query(sql, [email], async (err, results) => {
    if (err) return res.status(500).json({ message: "Database error ❌" });
    if (results.length === 0)
      return res.status(404).json({ message: "User not found ❌" });

    const user = results[0];

    if (!user.reset_token || !user.reset_expires)
      return res
        .status(400)
        .json({ message: "No reset request found. Please request a code first." });

    if (new Date() > new Date(user.reset_expires))
      return res
        .status(400)
        .json({ message: "Verification code expired. Request a new one." });

    if (user.reset_token !== code)
      return res.status(400).json({ message: "Invalid verification code ❌" });

    const hashed = await bcrypt.hash(newPassword, 10);
    const updateSql =
      "UPDATE users SET password = ?, reset_token = NULL, reset_expires = NULL WHERE email = ?";
    db.query(updateSql, [hashed, email], (updateErr) => {
      if (updateErr)
        return res.status(500).json({ message: "Failed to update password ❌" });

      return res.status(200).json({ message: "Password reset successful ✅" });
    });
  });
};
// ============================
// 🧑‍🤝‍🧑 جلب كل المستخدمين (لخاصية المحادثات)
// ============================
exports.getAllUsers = (req, res) => {
  const query = `
    SELECT id, full_name, email, photo_url, role
    FROM users
    ORDER BY full_name ASC
  `;

  db.query(query, (err, results) => {
    if (err) {
      console.error("❌ Error fetching users:", err);
      return res.status(500).json({ message: "Server error while fetching users ❌" });
    }

    return res.status(200).json(results);
  });
  
};
