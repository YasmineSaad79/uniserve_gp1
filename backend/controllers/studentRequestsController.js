// controllers/studentRequestsController.js
const db = require('../db');
const admin = require('../config/firebase');

/* ========================================================================
 * Helpers
 * ====================================================================== */

/** إرسال Push لكل توكنات المستخدم من جدول uniserve.device_tokens */
async function sendPushToUser(userId, title, body, data = {}) {
  return new Promise((resolve, reject) => {
    const sql = `SELECT token FROM uniserve.device_tokens WHERE user_id = ?`;
    db.query(sql, [userId], async (err, rows) => {
      if (err) return reject(err);
      if (!rows?.length) return resolve({ sent: 0, failed: 0 });

      const tokens = rows.map(r => r.token).filter(Boolean);
      if (!tokens.length) return resolve({ sent: 0, failed: 0 });

      // FCM data يجب أن تكون Strings
      const dataStrings = {};
      for (const [k, v] of Object.entries(data || {})) {
        if (v === undefined || v === null) continue;
        dataStrings[String(k)] = String(v);
      }

      const message = {
        tokens,
        notification: { title, body },
        data: dataStrings,
      };

      try {
        const res = await admin.messaging().sendEachForMulticast(message);
        resolve({ sent: res.successCount, failed: res.failureCount });
      } catch (e) {
        reject(e);
      }
    });
  });
}

/** جلب (id) الداخلي للطالب من جدول uniserve.students عبر student_id (رقم الجامعة) */
function getInternalStudentIdByUniversityId(studentUniId) {
  return new Promise((resolve, reject) => {
    const q = `SELECT id FROM uniserve.students WHERE student_id = ? LIMIT 1`;
    db.query(q, [studentUniId], (err, rows) => {
      if (err) return reject(err);
      resolve(rows?.[0]?.id || null);
    });
  });
}

/** جلب user_id للطالب انطلاقًا من students.id */
function getStudentUserIdByInternalId(internalStudentId) {
  return new Promise((resolve, reject) => {
    const q = `SELECT user_id FROM uniserve.students WHERE id = ? LIMIT 1`;
    db.query(q, [internalStudentId], (err, rows) => {
      if (err) return reject(err);
      resolve(rows?.[0]?.user_id || null);
    });
  });
}

/** محاولة جلب كل مستخدمي مركز الخدمة؛ وإلا fallback إلى ENV أو 19 */
async function getServiceCenterUserIds() {
  // غيّر القيم داخل IN بما يناسب أدوارك الفعلية لو مختلفة
  const roles = ['center', 'service_center', 'services_center', 'center_admin'];
  const placeholders = roles.map(() => '?').join(',');
  const q = `
    SELECT id FROM uniserve.users
    WHERE role IN (${placeholders})
  `;
  const rows = await new Promise((resolve, reject) => {
    db.query(q, roles, (err, res) => (err ? reject(err) : resolve(res || [])));
  });

  let ids = rows.map(r => r.id).filter(Boolean);
  if (!ids.length) {
    const envId = Number(process.env.SERVICE_CENTER_USER_ID);
    ids = [Number.isFinite(envId) ? envId : 19]; // fallback
  }
  return ids;
}

/** (اختياري) جلب بيانات مستخدم */
function getUserBasic(userId) {
  return new Promise((resolve, reject) => {
    db.query(
      `SELECT id, full_name FROM uniserve.users WHERE id = ? LIMIT 1`,
      [userId],
      (err, rows) => (err ? reject(err) : resolve(rows?.[0] || null))
    );
  });
}

/* ========================================================================
 * Controllers
 * ====================================================================== */

/**
 * Create new custom request + إشعار لمركز الخدمة
 * - body: { student_id (university number), title, description }
 */
exports.createRequest = async (req, res) => {
  try {
    const { student_id, title, description } = req.body; // student_id هنا رقم الجامعة (string)

    if (!student_id || !title || !description) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // 1) احصل على الـ id الداخلي للطالب + user_id للطالب
    const internalStudentId = await getInternalStudentIdByUniversityId(student_id);
    if (!internalStudentId) {
      return res
        .status(404)
        .json({ error: `Student with university ID ${student_id} not found` });
    }
    const studentUserId = await getStudentUserIdByInternalId(internalStudentId);

    // 2) أدخل الطلب
    const insertQuery = `
      INSERT INTO uniserve.student_custom_requests (student_id, title, description)
      VALUES (?, ?, ?)
    `;
    const insertResult = await new Promise((resolve, reject) => {
      db.query(insertQuery, [internalStudentId, title.trim(), description.trim()], (err, result) =>
        err ? reject(err) : resolve(result)
      );
    });

    const requestId = insertResult.insertId;

    // 3) جهّز إشعار لمركز الخدمة
    const centerIds = await getServiceCenterUserIds();
    const notifTitle = ' New Service Proposal';
    const notifBody  = ` Srudent send a suggestion: ${title}`;
    const payloadObj = { custom_request_id: requestId, student_user_id: studentUserId };
    const payloadStr = JSON.stringify(payloadObj);

    // 3.1) سجّل إشعار في جدول notifications لكل مركز خدمة
    const insNotif = `
      INSERT INTO uniserve.notifications
        (type, sender_user_id, receiver_id, activity_id, title, body, payload, status, is_read)
      VALUES ('volunteer_request', ?, ?, NULL, ?, ?, ?, 'unread', 0)
    `;

    for (const centerUserId of centerIds) {
      await new Promise((resolve, reject) => {
        db.query(
          insNotif,
          [studentUserId, centerUserId, notifTitle, notifBody, payloadStr],
          (err) => (err ? reject(err) : resolve())
        );
      });
      // 3.2) أرسل Push لكل مركز خدمة
      await sendPushToUser(centerUserId, notifTitle, notifBody, {
        custom_request_id: requestId,
        student_user_id: studentUserId,
        type: 'volunteer_request',
      });
    }

    // 4) رجّع الطلب الذي تم إنشاؤه
    const selectQuery = `
      SELECT request_id, student_id, title, description, status, created_at
      FROM uniserve.student_custom_requests
      WHERE request_id = ?
    `;
    const newRequest = await new Promise((resolve, reject) => {
      db.query(selectQuery, [requestId], (err, rows) =>
        err ? reject(err) : resolve(rows?.[0] || null)
      );
    });

    return res.status(201).json({
      success: true,
      data: newRequest,
      message: 'A request has been created and the serve center has been notified',
    });
  } catch (err) {
    console.error('Error creating student request:', err);
    return res.status(500).json({ error: 'Server error' });
  }
};

/**
 * Get all requests for a given student (university number)
 * - params: :studentId (رقم الجامعة)
 */
exports.getRequestsByStudent = async (req, res) => {
  try {
    const studentUniId = req.params.studentId; // university number (string)
    if (!studentUniId) {
      return res.status(400).json({ error: 'Invalid student id' });
    }

    // 1) id الداخلي
    const internalStudentId = await getInternalStudentIdByUniversityId(studentUniId);
    if (!internalStudentId) {
      return res
        .status(404)
        .json({ error: `Student with university ID ${studentUniId} not found` });
    }

    // 2) الطلبات
    const query = `
      SELECT request_id, student_id, title, description, status, created_at
      FROM uniserve.student_custom_requests
      WHERE student_id = ?
      ORDER BY created_at DESC
    `;
    const rows = await new Promise((resolve, reject) => {
      db.query(query, [internalStudentId], (err, result) =>
        err ? reject(err) : resolve(result)
      );
    });

    return res.status(200).json(rows);
  } catch (err) {
    console.error('Error fetching student requests:', err);
    return res.status(500).json({ error: 'Server error' });
  }
};

/**
 * Update request status by service center (accept / reject)
 * - PATCH /api/student/requests/:id/status  { "status": "approved" | "rejected" }
 * - ينشئ إشعارًا للطالب (type: request_accepted/request_rejected) + Push
 */
exports.updateRequestStatus = async (req, res) => {
  try {
    const { id } = req.params;       // request_id
    const { status } = req.body;     // 'approved' | 'rejected'
    const actorUserId = req.user?.id; // المستخدم (السنتر) الذي اتخذ القرار

    if (!['approved', 'rejected'].includes(status)) {
      return res.status(400).json({ message: 'Invalid status value' });
    }

    // 1) جلب الطلب لمعرفة الطالب والعنوان + user_id للطالب
    const getQ = `
      SELECT r.request_id, r.student_id, r.title, r.status, s.user_id AS student_user_id
      FROM uniserve.student_custom_requests r
      JOIN uniserve.students s ON s.id = r.student_id
      WHERE r.request_id = ?
      LIMIT 1
    `;
    const reqRow = await new Promise((resolve, reject) => {
      db.query(getQ, [id], (err, rows) => (err ? reject(err) : resolve(rows?.[0] || null)));
    });
    if (!reqRow) return res.status(404).json({ message: 'Request not found' });

    const studentInternalId = reqRow.student_id;
    const studentUserId     = reqRow.student_user_id;
    const reqTitle          = reqRow.title;

    // 2) تحديث الحالة
    const updQ = `
      UPDATE uniserve.student_custom_requests
      SET status = ?, updated_at = CURRENT_TIMESTAMP
      WHERE request_id = ?
    `;
    await new Promise((resolve, reject) => {
      db.query(updQ, [status, id], (err) => (err ? reject(err) : resolve()));
    });

    // 3) تجهيز الإشعار للطالب
    const notifType  = status === 'approved' ? 'request_accepted' : 'request_rejected';
    const notifTitle = status === 'approved' ? 'request accepted' : ' request rejected ';
    const notifBody  = status === 'approved'
      ? ` approved: ${reqTitle}`
      : ` rejected: ${reqTitle}`;
    const payload = JSON.stringify({ request_id: id, decision_by: actorUserId });

    // 4) إنشاء إشعار في جدول notifications
    const insNotif = `
      INSERT INTO uniserve.notifications
      (type, sender_user_id, receiver_id, activity_id, title, body, payload, status, is_read)
      VALUES (?, ?, ?, NULL, ?, ?, ?, 'unread', 0)
    `;
    const backNotifId = await new Promise((resolve, reject) => {
      db.query(
        insNotif,
        [notifType, actorUserId, studentUserId, notifTitle, notifBody, payload],
        (err, result) => (err ? reject(err) : resolve(result.insertId))
      );
    });

    // 5) إرسال Push للطالب (لازم يكون حسب user_id للطالب لأن device_tokens.user_id يخزن هناك)
    await sendPushToUser(studentUserId, notifTitle, notifBody, {
      notification_id: backNotifId,
      request_id: id,
      status,
    });

    return res.json({ message: 'Status updated ', request_id: id, status });
  } catch (err) {
    console.error('Error updating request status:', err);
    return res.status(500).json({ error: 'Server error' });
  }
};
