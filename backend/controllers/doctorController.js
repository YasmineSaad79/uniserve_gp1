const db = require("../db");
const bcrypt = require("bcrypt");

// =====================================================
//  Get doctor profile
// =====================================================
exports.getDoctorProfile = (req, res) => {
  const doctorId = req.params.doctorId;

  const sql = `
    SELECT 
      u.id,
      u.full_name,
      u.email,
      u.photo_url,
      u.role,
      d.phone_number,
      d.service_center_id
    FROM users u
    LEFT JOIN doctors d ON u.id = d.user_id
    WHERE u.id = ? AND u.role = 'doctor'
  `;

  db.query(sql, [doctorId], (err, results) => {
    if (err) return res.status(500).json({ message: "Database error" });
    if (results.length === 0)
      return res.status(404).json({ message: "Doctor not found" });

    res.json(results[0]);
  });
};

// =====================================================
//  Update doctor profile (name + phone + optional photo)
//     SAME endpoint for saving text + photo
// =====================================================
exports.updateDoctorProfile = (req, res) => {
  const doctorId = req.params.doctorId;

  // امنع أي undefined → لازم تكون string
  const full_name = req.body.full_name || "";
  const phone_number = req.body.phone_number || "";

  //  ممنوع تغيير الإيميل
  // الـ Flutter لازم يبعت الإيميل بس ما نستخدمه
  const ignoreEmail = req.body.email;

  //  إذا فيه صورة:
  const photoUrl = req.file ? `/uploads/${req.file.filename}` : null;

  //  تحديث users (الاسم + الصورة إن وجدت)
  const sqlUser = photoUrl
    ? `UPDATE users SET full_name = ?, photo_url = ? WHERE id = ?`
    : `UPDATE users SET full_name = ? WHERE id = ?`;

  const paramsUser = photoUrl
    ? [full_name, photoUrl, doctorId]
    : [full_name, doctorId];

  db.query(sqlUser, paramsUser, (err1) => {
    if (err1) {
      console.error("error user update", err1);
      return res.status(500).json({ message: "Error updating user data" });
    }

    //  تحديث doctors (phone)
    const sqlDoc = `UPDATE doctors SET phone_number = ? WHERE user_id = ?`;

    db.query(sqlDoc, [phone_number, doctorId], (err2) => {
      if (err2) {
        console.error("error doctor update", err2);
        return res
          .status(500)
          .json({ message: "Error updating doctor phone" });
      }

      return res.json({
        message: "Profile updated successfully ",
        photo_url: photoUrl || undefined,
      });
    });
  });
};

// =====================================================
//  Change password
// =====================================================
exports.changePassword = async (req, res) => {
  const doctorId = req.params.doctorId;
  const { newPassword } = req.body;

  if (!newPassword || newPassword.length < 6) {
    return res.status(400).json({ message: "Password too short" });
  }

  try {
    const hashed = await bcrypt.hash(newPassword, 10);
    db.query(
      "UPDATE users SET password = ? WHERE id = ?",
      [hashed, doctorId],
      (err) => {
        if (err)
          return res.status(500).json({ message: "Database update failed" });

        res.json({ message: "Password updated successfully" });
      }
    );
  } catch (e) {
    res.status(500).json({ message: "Server error hashing password" });
  }
};

// =====================================================
//  Students assigned to a doctor
// =====================================================
exports.getDoctorStudentsForDoctor = async (req, res) => {
  try {
    const doctorId = req.user.id;

    const [students] = await db.promise().query(
      `
      SELECT DISTINCT
        u.id,
        u.full_name,
        u.email,
        u.photo_url,
        s.student_id
      FROM student_doctor sd
      JOIN users u ON u.id = sd.student_user_id
      JOIN students s ON s.user_id = u.id
      WHERE sd.doctor_user_id = ?
      ORDER BY u.full_name ASC
      `,
      [doctorId]
    );

    res.json({
      success: true,
      count: students.length,
      data: students,
    });
  } catch (err) {
    console.error("❌ getDoctorStudentsForDoctor error:", err);
    return res.status(500).json({ message: "Server error" });
  }
};
