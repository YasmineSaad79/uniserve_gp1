const db = require("../db");

//
// =====================
//  Get Volunteer Requests
// =====================
exports.getVolunteerRequests = async (req, res) => {
  try {
    const centerUserId = req.user.id;

    // استخراج center_id من جدول center
    const [center] = await db
      .promise()
      .query("SELECT center_id FROM center WHERE user_id = ?", [centerUserId]);

    if (!center.length) {
      return res.status(404).json({ message: "Center not found" });
    }

    const centerId = center[0].center_id;

    // احضار كل ال volunteer_requests للخدمات التي أنشأها هذا المركز
    const sql = `
      SELECT 
        vr.id AS request_id,
        vr.status,
        vr.created_at,
        u.id AS student_id,
        u.full_name AS student_name,
        u.photo_url AS student_photo,
        s.service_id AS activity_id,
        s.title AS activity_title
      FROM volunteer_requests vr
      JOIN users u ON u.id = vr.student_id
      JOIN services s ON s.service_id = vr.activity_id
      WHERE s.created_by = ? 
      ORDER BY vr.created_at DESC
    `;

    const [rows] = await db.promise().query(sql, [centerUserId]);

    res.json(rows);
  } catch (err) {
    console.log("❌ Error getVolunteerRequests:", err);
    res.status(500).json({ message: "Server error" });
  }
};

//
// =====================
//  Accept Request
// =====================
exports.acceptVolunteerRequest = async (req, res) => {
  try {
    const requestId = req.params.id;

    // 1) جلب بيانات الطلب من جدول volunteer_requests
    const [reqRows] = await db.promise().query(
      `SELECT student_id, activity_id
       FROM volunteer_requests
       WHERE id = ?`,
      [requestId]
    );

    if (!reqRows.length) {
      return res.status(404).json({ message: "Volunteer request not found" });
    }

    const { student_id, activity_id } = reqRows[0];

    // 2) تحديث حالة الطلب
    await db.promise().query(
      `UPDATE volunteer_requests
       SET status='accepted', updated_at=NOW()
       WHERE id = ?`,
      [requestId]
    );

    // 3) جلب الفورم من services
    const [serviceRows] = await db.promise().query(
      `SELECT form_template_path
       FROM services
       WHERE service_id = ?`,
      [activity_id]
    );

    const template = serviceRows.length ? serviceRows[0].form_template_path : null;

    // 4) إنشاء السبيميشن
    await db.promise().query(
      `INSERT INTO activity_submissions
       (student_id, activity_id, template_path, status, created_at)
       VALUES (?, ?, ?, 'pending', NOW())`,
      [student_id, activity_id, template]
    );

    res.json({ message: "Volunteer request accepted & submission created" });

  } catch (err) {
    console.log(err);
    res.status(500).json({ message: "Server error" });
  }
};





//
// =====================
//  Reject Request
// =====================
exports.rejectVolunteerRequest = async (req, res) => {
  try {
    const requestId = req.params.id;

    const sql = `
      UPDATE volunteer_requests 
      SET status='rejected', updated_at=NOW()
      WHERE id = ?
    `;

    const [result] = await db.promise().query(sql, [requestId]);

    if (result.affectedRows === 0)
      return res.status(404).json({ message: "Request not found" });

    res.json({ message: "Request rejected successfully" });
  } catch (err) {
    console.log(err);
    res.status(500).json({ message: "Server error" });
  }
};

//
// =====================
//  Get Custom Requests
// =====================
exports.getCustomRequests = async (req, res) => {
  try {
    const sql = `
      SELECT 
        r.request_id,
        r.title,
        r.description,
        r.status,
        r.created_at,
        u.full_name AS student_name,
        u.photo_url AS student_photo
      FROM student_custom_requests r
      JOIN users u ON u.id = r.student_id
      ORDER BY r.created_at DESC
    `;

    const [rows] = await db.promise().query(sql);
    res.json(rows);
  } catch (err) {
    console.log("❌ Error getCustomRequests:", err);
    res.status(500).json({ message: "Server error" });
  }
};

//
// ===============================
//  Get Approved Volunteer Requests
// ===============================
exports.getApprovedVolunteerRequests = async (req, res) => {
  try {
    const sql = `
      SELECT 
        vr.id AS request_id,
        vr.status,
        vr.created_at,
        u.full_name AS student_name,
        u.photo_url AS student_photo,
        s.title AS activity_title
      FROM volunteer_requests vr
      JOIN users u ON u.id = vr.student_id
      JOIN services s ON s.service_id = vr.activity_id
      WHERE vr.status = 'accepted'
      ORDER BY vr.created_at DESC
    `;

    const [rows] = await db.promise().query(sql);
    res.json(rows);
  } catch (err) {
    console.log("❌ Error getApprovedVolunteerRequests:", err);
    res.status(500).json({ message: "Server error" });
  }
};

//
// ===============================
//  Get Approved Custom Requests
// ===============================
exports.getApprovedCustomRequests = async (req, res) => {
  try {
    const sql = `
      SELECT 
        r.request_id,
        r.title,
        r.description,
        r.status,
        r.created_at,
        u.full_name AS student_name,
        u.photo_url AS student_photo
      FROM student_custom_requests r
      JOIN users u ON u.id = r.student_id
      WHERE r.status = 'approved'
      ORDER BY r.created_at DESC
    `;

    const [rows] = await db.promise().query(sql);
    res.json(rows);
  } catch (err) {
    console.log("❌ Error getApprovedCustomRequests:", err);
    res.status(500).json({ message: "Server error" });
  }

};
//
// ==========================
//  Update Custom Request Status
// ==========================
exports.updateCustomRequestStatus = async (req, res) => {
  try {
    if (!req.body || !req.body.status) {
      return res.status(400).json({ message: "Missing status in body" });
    }

    const { status } = req.body;
    const requestId = req.params.id;

    if (!["approved", "rejected"].includes(status)) {
      return res.status(400).json({ message: "Invalid status value" });
    }

    const sql = `
      UPDATE student_custom_requests
      SET status = ?, updated_at = NOW()
      WHERE request_id = ?
    `;

    const [result] = await db.promise().query(sql, [status, requestId]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Custom request not found" });
    }

    res.json({ message: `Custom request ${status}` });

  } catch (err) {
    console.log("❌ Error updateCustomRequestStatus:", err);
    res.status(500).json({ message: "Server error" });
  }
};

