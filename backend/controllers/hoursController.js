const db = require("../db");

// =======================================================
// 1) Process Hours (Service Center Button)
// =======================================================
exports.processHours = async (req, res) => {
  try {
    console.log(" Processing hours...");

    const [rows] = await db.promise().query(
      `
      SELECT 
        sd.student_user_id,
        sd.doctor_user_id,
        SUM(sub.earned_hours) AS total_hours
      FROM activity_submissions sub
      JOIN student_doctor sd ON sd.student_user_id = sub.student_id
      WHERE sub.status = 'approved'
      GROUP BY sd.student_user_id, sd.doctor_user_id
      `
    );

    if (!rows.length) {
      return res.status(400).json({ message: "No hours available to process." });
    }

    const insertValues = rows.map((r) => [
      r.student_user_id,
      r.doctor_user_id,
      r.total_hours,
      r.total_hours >= 50 ? "pass" : "fail"
    ]);

    await db.promise().query(
      `
      INSERT INTO student_hours_summary
      (student_user_id, doctor_user_id, total_hours, result)
      VALUES ?
      ON DUPLICATE KEY UPDATE
        total_hours = VALUES(total_hours),
        result = VALUES(result),
        calculated_at = NOW()
      `,
      [insertValues]
    );

    console.log(" Hours processed successfully!");
    res.json({ message: "Hours processed successfully!" });

  } catch (err) {
    console.error(" Error processing hours:", err);
    res.status(500).json({ message: "Server error" });
  }
};


// =======================================================
//  2) Doctor → View processed hours for assigned students
// =======================================================
exports.getDoctorSummary = async (req, res) => {
  try {
    const doctorId = req.user.id; // من التوكن

    const [rows] = await db.promise().query(
      `
      SELECT 
        u.id AS student_user_id,        -- ⭐⭐⭐ هذا المهم
        u.full_name,
        u.student_id,
        summary.total_hours,
        summary.result,
        summary.calculated_at
      FROM student_hours_summary summary
      JOIN users u ON u.id = summary.student_user_id
      WHERE summary.doctor_user_id = ?
      ORDER BY u.full_name
      `,
      [doctorId]
    );

    res.json(rows);

  } catch (err) {
    console.error(" Error fetching doctor summary:", err);
    res.status(500).json({ message: "Server error" });
  }
};
exports.sendResultToStudent = async (req, res) => {
  try {
    const doctorUserId = req.user.id; // من التوكن
    const studentUserId = req.params.studentUserId;

    // 1️⃣ جلب النتيجة
    const [rows] = await db.promise().query(
      `
      SELECT total_hours, result, status
      FROM student_hours_summary
      WHERE student_user_id = ?
        AND doctor_user_id = ?
      `,
      [studentUserId, doctorUserId]
    );

    if (!rows.length) {
      return res.status(404).json({ message: "Result not found." });
    }

    const summary = rows[0];

    if (summary.status === "sent_to_student") {
      return res
        .status(400)
        .json({ message: "Result already sent to student." });
    }

    // 2️⃣ إنشاء إشعار للطالب (✔️ مطابق للـ DB)
    await db.promise().query(
      `
      INSERT INTO notifications
      (
        type,
        receiver_id,
        sender_user_id,
        title,
        body,
        payload
      )
      VALUES
      (
        'academic_result',
        ?,
        ?,
        ?,
        ?,
        ?
      )
      `,
      [
        studentUserId,      // receiver_id
        doctorUserId,       // sender_user_id
        "Course Result",
        summary.result === "pass"
          ? "Congratulations! You have passed the course 🎉"
          : "Unfortunately, you have failed the course.",
        JSON.stringify({
          result: summary.result,
          total_hours: summary.total_hours,
        }),
      ]
    );

    // 3️⃣ تحديث الحالة
    await db.promise().query(
      `
      UPDATE student_hours_summary
      SET status = 'sent_to_student'
      WHERE student_user_id = ?
        AND doctor_user_id = ?
      `,
      [studentUserId, doctorUserId]
    );

    res.json({ message: "Result sent to student successfully." });

  } catch (err) {
    console.error("❌ Error sending result:", err);
    res.status(500).json({ message: "Server error" });
  }
};
