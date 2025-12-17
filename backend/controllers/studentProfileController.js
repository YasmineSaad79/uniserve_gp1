//  backend/controllers/studentProfileController.js

const db = require("../db");
const path = require("path");


exports.getStudentProfile = async (req, res) => {
  const studentId = req.params.studentId;

  try {
    //  أولاً: جلب بيانات الطالب
    const [studentRows] = await db
      .promise()
      .query(
        `
        SELECT 
          u.id AS user_id,       
          u.full_name, 
          u.email, 
          u.photo_url,
          s.phone_number, 
          s.preferences, 
          s.hobbies
        FROM users u
        JOIN students s ON u.id = s.user_id
        WHERE s.student_id = ?
        `,
        [studentId]
      );

    if (!studentRows.length)
      return res.status(404).json({ message: "Student not found" });

    const student = studentRows[0];

    //  ثانيًا: نجيب الـ service_center_id المرتبط بأنشطة الطالب
    const [centerRows] = await db
      .promise()
      .query(
        `
        SELECT srv.created_by AS service_center_id
        FROM volunteer_requests vr
        JOIN services srv ON vr.activity_id = srv.service_id
        JOIN users sc ON sc.id = srv.created_by
        WHERE vr.student_id = ?
        ORDER BY vr.created_at DESC
        LIMIT 1
        `,
        [student.user_id]
      );

    // إذا الطالب ما قدم على أي نشاط، خليه null أو مركز افتراضي
    student.service_center_id =
      centerRows.length > 0 ? centerRows[0].service_center_id : 19; // 19 هو السنتر الرئيسي

    console.log(" Student profile data sent:", student);
    res.json(student);
  } catch (err) {
    console.error(" Database error:", err);
    res.status(500).json({ message: "Database error" });
  }
};



//  تحديث بيانات الطالب
exports.updateStudentProfile = (req, res) => {
  const studentId = req.params.studentId;
  const { full_name, email, phone_number, preferences, hobbies } = req.body;

  let photoUrl = null;
  if (req.file) {
    photoUrl = `/uploads/${req.file.filename}`;
  }

  let updateUserQuery = `UPDATE users SET full_name = ?, email = ?`;
  const updateUserParams = [full_name, email];

  if (photoUrl) {
    updateUserQuery += `, photo_url = ?`;
    updateUserParams.push(photoUrl);
  }

  updateUserQuery += ` WHERE id = (SELECT user_id FROM students WHERE student_id = ?)`;
  updateUserParams.push(studentId);

  db.query(updateUserQuery, updateUserParams, (err1, results1) => {
    if (err1) {
      console.error(" Error updating user:", err1);
      return res.status(500).json({ message: "Error updating user" });
    }

    if (results1.affectedRows === 0) {
      return res.status(404).json({ message: "User not found or nothing to update." });
    }

    const updateStudentQuery = `
      UPDATE students 
      SET phone_number = ?, preferences = ?, hobbies = ?
      WHERE student_id = ?`;

    db.query(
      updateStudentQuery,
      [phone_number, preferences, hobbies, studentId],
      (err2, results2) => {
        if (err2) {
          console.error(" Error updating student:", err2);
          return res.status(500).json({ message: "Error updating student profile" });
        }

        res.status(200).json({
          message: "Profile updated successfully ",
          photo_url: photoUrl,
        });
      }
    );
  });
};

//  هذه هي الدالة الجديدة والمستقلة
exports.getUserIdByStudentId = (req, res) => {
  const studentId = req.params.studentId;

  const sql = `SELECT user_id FROM students WHERE student_id = ?`;
  db.query(sql, [studentId], (err, results) => {
    if (err) return res.status(500).json({ error: "DB error" });
    if (results.length === 0)
      return res.status(404).json({ error: "Student not found" });

    res.json({ user_id: results[0].user_id });
  });
};
