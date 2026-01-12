const db = require("../db");

// ===============================================
// GET: Get submission for student & activity
// ===============================================
exports.getStudentSubmission = async (req, res) => {
  try {
    const { studentId, activityId } = req.params;

    const [rows] = await db
      .promise()
      .query(
        `SELECT * FROM activity_submissions 
         WHERE student_id = ? AND activity_id = ?`,
        [studentId, activityId]
      );

    if (!rows.length) {
      return res.status(404).json({ message: "Submission not found" });
    }

    res.json(rows[0]);
  } catch (err) {
    console.log(" Error getStudentSubmission:", err);
    res.status(500).json({ message: "Server error" });
  }
};

// ===============================================
// POST: Student uploads signed submission file
// ===============================================
/*
exports.uploadSubmissionFile = async (req, res) => {
  try {
    const { studentId, activityId } = req.body;

    if (!req.file) {
      return res.status(400).json({ message: "No file uploaded" });
    }

    const filePath = "/uploads/submissions/" + req.file.filename;

    // 1) امسحي أي submissions قديمة لنفس الطالب ولنفس النشاط
    await db.promise().query(
      `DELETE FROM activity_submissions 
       WHERE student_id = ? AND activity_id = ?`,
      [studentId, activityId]
    );

    //  2) أضيفي submission جديد دائماً
    await db.promise().query(
      `INSERT INTO activity_submissions
        (student_id, activity_id, submitted_file_path, status, created_at)
       VALUES (?, ?, ?, 'submitted', NOW())`,
      [studentId, activityId, filePath]
    );

    res.json({
      message: "Submission uploaded successfully",
      file: filePath,
    });

  } catch (err) {
    console.log(" uploadSubmission Error:", err);
    res.status(500).json({ message: "Server error" });
  }
};

*/
exports.uploadSubmissionFile = async (req, res) => {
  try {
    console.log(" BODY:", req.body);
    console.log(" FILE:", req.file);

    const studentId = req.body.studentId || req.body.student_id;
    const activityId = req.body.activityId || req.body.activity_id;


    if (!studentId || !activityId) {
      return res.status(400).json({
        message: "Missing studentId or activityId",
        body: req.body
      });
    }

    if (!req.file) {
      return res.status(400).json({ message: "No file uploaded" });
    }

    const filePath = "/uploads/submissions/" + req.file.filename;

    await db.promise().query(
      `DELETE FROM activity_submissions 
       WHERE student_id = ? AND activity_id = ?`,
      [studentId, activityId]
    );

    await db.promise().query(
      `INSERT INTO activity_submissions
        (student_id, activity_id, submitted_file_path, status, created_at)
       VALUES (?, ?, ?, 'submitted', NOW())`,
      [studentId, activityId, filePath]
    );

    res.json({
      message: "Submission uploaded successfully",
      file: filePath,
    });

  } catch (err) {
    console.log(" uploadSubmission Error:", err);
    res.status(500).json({
      message: "Server error",
      error: err.message
    });
  }
  console.log("BODY:", req.body);
console.log("FILE:", req.file);

};

// ===============================================
// GET: All submissions for center to review
// ===============================================
exports.getCenterSubmissions = async (req, res) => {
  try {
    const centerUserId = req.user.id;

    const [rows] = await db.promise().query(
      `
      SELECT 
        sub.submission_id,
        sub.status,
        sub.template_path,
        sub.submitted_file_path,
        u.full_name AS student_name,
        u.photo_url AS student_photo,
        s.title AS activity_title,
        s.service_id AS activity_id
      FROM activity_submissions sub
      JOIN services s ON s.service_id = sub.activity_id
      JOIN users u ON u.id = sub.student_id
      WHERE s.created_by = ?
      ORDER BY sub.created_at DESC
      `,
      [centerUserId]
    );

    res.json(rows);
  } catch (err) {
    console.error(" Error in getCenterSubmissions:", err);
    res.status(500).json({ message: "Server error" });
  }
};
exports.getStudentAllSubmissions = async (req, res) => {
  try {
    const { studentId } = req.params;

    const [rows] = await db.promise().query(
      `
      SELECT sub.*, s.title AS activity_title
      FROM activity_submissions sub
      JOIN services s ON s.service_id = sub.activity_id
      WHERE sub.student_id = ?
        AND sub.status = 'approved'
      ORDER BY sub.created_at DESC
      `,
      [studentId]
    );

    res.json(rows);
  } catch (err) {
    console.log(" Error getStudentAllSubmissions:", err);
    res.status(500).json({ message: "Server error" });
  }
};



exports.approveSubmission = async (req, res) => {
  try {
    const submissionId = req.params.id;

    // 1) احضار السبيميشن
    const [rows] = await db.promise().query(
      `SELECT student_id, activity_id 
       FROM activity_submissions 
       WHERE submission_id = ?`,
      [submissionId]
    );

    if (!rows.length) {
      return res.status(404).json({ message: "Submission not found" });
    }

    const { student_id, activity_id } = rows[0];

    // 2) احضار ساعات النشاط
    const [serviceRows] = await db.promise().query(
      `SELECT progress_points FROM services WHERE service_id = ?`,
      [activity_id]
    );

    const hours = serviceRows.length ? serviceRows[0].progress_points : 0;

    // 3) احضار مجموع ساعات الطالب الحالية
    const [sumRows] = await db.promise().query(
      `SELECT SUM(earned_hours) AS total
       FROM activity_submissions
       WHERE student_id = ? AND status = 'approved'`,
      [student_id]
    );

    const currentHours = sumRows[0].total || 0;

    // 4) التحقق من الحد الأقصى (50 ساعة)
    if (currentHours >= 50) {
      return res.status(400).json({
        message: "This student already reached the 50-hour limit.",
        blocked: true
      });
    }

    // لو الساعات القادمة تتجاوز الحد → قصّها بحيث لا تتعدى 50
    let finalHours = hours;
    if (currentHours + hours > 50) {
      finalHours = 50 - currentHours; // كم ناقص له فقط
    }

    // 5) تحديث السبيميشن
    await db.promise().query(
      `UPDATE activity_submissions 
       SET status='approved', earned_hours=?, updated_at=NOW()
       WHERE submission_id = ?`,
      [finalHours, submissionId]
    );

    res.json({
      message: "Submission approved",
      earned_hours: finalHours,
      total_hours_after: currentHours + finalHours
    });

  } catch (err) {
    console.log(err);
    res.status(500).json({ message: "Server error" });
  }
};

// ===============================================
// PUT: Reject submission
// ===============================================
exports.rejectSubmission = async (req, res) => {
  try {
    const submissionId = req.params.id;

    // التحقق من وجود السبيميشن
    const [rows] = await db.promise().query(
      `SELECT submission_id FROM activity_submissions WHERE submission_id = ?`,
      [submissionId]
    );

    if (!rows.length) {
      return res.status(404).json({ message: "Submission not found" });
    }

    // تحديث الحالة إلى مرفوض
    await db.promise().query(
      `UPDATE activity_submissions 
       SET status = 'rejected', updated_at = NOW()
       WHERE submission_id = ?`,
      [submissionId]
    );

    res.json({
      success: true,
      message: "Submission rejected successfully"
    });

  } catch (err) {
    console.log(" Error rejectSubmission:", err);
    res.status(500).json({ message: "Server error" });
  }
};


exports.getCenterSummary = async (req, res) => {
  try {
    const centerUserId = req.user.id;

    // 1) احضار center_id
    const [centerRows] = await db.promise().query(
      `SELECT center_id FROM center WHERE user_id = ?`,
      [centerUserId]
    );

    if (!centerRows.length) {
      return res.status(404).json({ message: "Center not found" });
    }

    const centerId = centerRows[0].center_id;

    // 2) جميع الخدمات الخاصة بالسنتر
    const [services] = await db.promise().query(
      `SELECT service_id FROM services WHERE created_by = ?`,
      [centerUserId]
    );

    if (!services.length) return res.json([]);

    const serviceIds = services.map((s) => s.service_id);

    // 3) نجلب فقط submissions التي فيها PDF (submitted_file_path موجود)
    const [rows] = await db.promise().query(
      `
      SELECT 
        s.submission_id,
        s.student_id,
        s.activity_id,
        s.status,
        s.earned_hours,
        s.submitted_file_path AS file_path,
        srv.title AS activity_title,
        u.full_name,
        u.photo_url
      FROM activity_submissions s
      JOIN services srv ON srv.service_id = s.activity_id
      JOIN users u ON u.id = s.student_id
      WHERE 
        s.activity_id IN (?) 
        AND s.submitted_file_path IS NOT NULL
      ORDER BY s.student_id, s.submission_id DESC
      `,
      [serviceIds]
    );

    if (!rows.length) return res.json([]);

    // 4) تجميع حسب الطالب
    const summary = {};

    rows.forEach((item) => {
      if (!summary[item.student_id]) {
        summary[item.student_id] = {
          student_id: item.student_id,
          full_name: item.full_name,
          photo_url: item.photo_url,
          total_hours: 0,
          submissions: []
        };
      }

      summary[item.student_id].submissions.push({
        submission_id: item.submission_id,
        activity_title: item.activity_title,
        status: item.status,
        earned_hours: item.earned_hours,
        uploaded_file: item.file_path
      });

      if (item.status === "approved") {
        summary[item.student_id].total_hours += item.earned_hours || 0;
      }
    });

    res.json(Object.values(summary));

  } catch (err) {
    console.log(" Error getCenterSummary:", err);
    res.status(500).json({ message: "Server error" });
  }
  
};
