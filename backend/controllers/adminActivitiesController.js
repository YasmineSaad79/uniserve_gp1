// ============================
//  backend/controllers/adminActivitiesController.js
// ============================

const db = require("../db");

// ============================
//  Admin: ربط طالب مع دكتور
// ============================
exports.assignStudentToDoctor = async (req, res) => {
  try {
    const { studentId, doctorId } = req.body;

    if (!studentId || !doctorId) {
      return res.status(400).json({
        message: "studentId و doctorId مطلوبين ",
      });
    }

    // التحقق من صحة الدور
    const [rows] = await db.promise().query(
      "SELECT id, role FROM users WHERE id IN (?, ?)",
      [studentId, doctorId]
    );

    if (rows.length !== 2) {
      return res
        .status(400)
        .json({ message: "Student أو Doctor غير موجودين " });
    }

    const student = rows.find((u) => u.id == studentId);
    const doctor = rows.find((u) => u.id == doctorId);

    if (student.role !== "student") {
      return res.status(400).json({
        message: "المستخدم المحدد كطالب ليس له دور student ",
      });
    }

    if (doctor.role !== "doctor") {
      return res.status(400).json({
        message: "المستخدم المحدد كدكتور ليس له دور doctor ",
      });
    }

    // إدخال أو تحديث الربط
    await db.promise().query(
      `
      INSERT INTO student_doctor (student_user_id, doctor_user_id)
      VALUES (?, ?)
      ON DUPLICATE KEY UPDATE doctor_user_id = VALUES(doctor_user_id)
      `,
      [studentId, doctorId]
    );

    return res.status(200).json({
      message: " تم ربط الطالب مع الدكتور بنجاح",
      data: { studentId, doctorId },
    });
  } catch (err) {
    console.error(" Error in assignStudentToDoctor:", err);
    return res.status(500).json({ message: "Server error " });
  }
};

// ============================
//  Admin: جلب طلاب دكتور معيّن
// ============================
exports.getDoctorStudents = async (req, res) => {
  try {
    const { doctorId } = req.params;

    if (!doctorId) {
      return res
        .status(400)
        .json({ message: "doctorId مطلوب في البارام " });
    }

    const [doc] = await db
      .promise()
      .query("SELECT id, role, full_name FROM users WHERE id = ?", [doctorId]);

    if (doc.length === 0 || doc[0].role !== "doctor") {
      return res
        .status(400)
        .json({ message: "هذا المستخدم ليس دكتورًا أو غير موجود " });
    }

    const [students] = await db.promise().query(
      `
      SELECT 
        u.id,
        u.full_name,
        u.email,
        u.student_id,
        u.photo_url
      FROM student_doctor sd
      JOIN users u ON u.id = sd.student_user_id
      WHERE sd.doctor_user_id = ?
      ORDER BY u.full_name ASC
      `,
      [doctorId]
    );

    return res.status(200).json({
      message: `طلاب الدكتور ${doc[0].full_name}`,
      count: students.length,
      data: students,
    });
  } catch (err) {
    console.error(" Error in getDoctorStudents:", err);
    return res.status(500).json({ message: "Server error " });
  }
};
