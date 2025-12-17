// controllers/notifications.controller.js
const db = require("../db");
const admin = require("../config/firebase");

/* ============================================================================
 * Helpers
 * ========================================================================== */

/** Safely parse JSON that may arrive as Buffer, string, or object */
function parseJsonSafe(raw) {
  try {
    if (raw == null) return {};
    if (Buffer.isBuffer(raw)) raw = raw.toString("utf8");
    if (typeof raw === "string") {
      const s = raw.trim();
      if (!s) return {};
      return JSON.parse(s);
    }
    if (typeof raw === "object") return raw;
    return {};
  } catch {
    return {};
  }
}

/** Send push notification to all devices for a given user_id */
async function sendPushToUser(userId, title, body, data = {}) {
  console.log(" sendPushToUser called for user:", userId, "title:", title);

  return new Promise((resolve, reject) => {
    const sql = `SELECT token FROM uniserve.device_tokens WHERE user_id = ?`;
    db.query(sql, [userId], async (err, rows) => {
      if (err) return reject(err);
      if (!rows?.length) return resolve({ sent: 0, failed: 0 });

      const tokens = rows.map((r) => r.token).filter(Boolean);
      if (!tokens.length) return resolve({ sent: 0, failed: 0 });

      const dataStrings = {};
      for (const [k, v] of Object.entries(data || {})) {
        if (v === undefined || v === null) continue;
        dataStrings[String(k)] = String(v);
      }

      //  هنا التعديل المهم
      const message = {
  tokens,
  notification: { title, body }, // للمود الخلفي فقط
  data: {
    type: "chat",
    title: String(title),
    body: String(body),
    ...dataStrings,
    click_action: "FLUTTER_NOTIFICATION_CLICK",
  },
};

      try {
        const res = await admin.messaging().sendEachForMulticast(message);
        console.log("Push result:", res.successCount, "sent,", res.failureCount, "failed");
        resolve({ sent: res.successCount, failed: res.failureCount });
      } catch (e) {
        console.error(" FCM send error:", e);
        reject(e);
      }
    });
  });
}

/** Get the service owner user_id and title for a given activity (service) */
function getServiceOwnerUserIdByActivity(activityId) {
  return new Promise((resolve, reject) => {
    const q = `
      SELECT c.user_id AS service_user_id, s.title
      FROM uniserve.services s
      JOIN uniserve.center c ON s.created_by = c.center_id
      WHERE s.service_id = ?
      LIMIT 1
    `;
    db.query(q, [activityId], (err, rows) => {
      if (err) return reject(err);
      if (!rows?.length) return resolve(null);
      resolve(rows[0]);
    });
  });
}

/** Get basic user info */
function getUserBasic(userId) {
  return new Promise((resolve, reject) => {
    db.query(
      `SELECT id, full_name FROM uniserve.users WHERE id = ? LIMIT 1`,
      [userId],
      (err, rows) => (err ? reject(err) : resolve(rows?.[0] || null))
    );
  });
}

/* ============================================================================
 * Controllers
 * ========================================================================== */

/** 1) Register/Update device token */
exports.registerDeviceToken = (req, res) => {
  console.log(" ENTERED registerDeviceToken()");
  console.log(" BODY:", req.body);
  console.log(" USER:", req.user);

  const { token, platform = "android" } = req.body;
  const userId = req.user?.id;

  if (!userId) {
    console.warn(" No user attached to token registration");
    return res.status(401).json({ message: "User not authenticated" });
  }

  if (!token) return res.status(400).json({ message: "token is required" });

  const sql = `
    INSERT INTO uniserve.device_tokens (user_id, token, platform)
    VALUES (?, ?, ?)
    ON DUPLICATE KEY UPDATE token = VALUES(token), platform = VALUES(platform), created_at = CURRENT_TIMESTAMP
  `;

  db.query(sql, [userId, token, platform], (err) => {
    if (err) {
      console.error(" Error saving FCM token:", err);
      return res.status(500).json({ message: "DB error", error: err.message });
    }
    console.log(` Device token saved for user_id = ${userId}`);
    res.json({ message: "Token registered ", user_id: userId });
  });
};

/** 2) Student creates a volunteer request */
exports.createVolunteerRequest = async (req, res) => {
  try {
    const studentId = req.user.id;
    const activity_id = req.body.activity_id ?? req.body.activityId;
    if (!activity_id)
      return res.status(400).json({ message: "activity_id is required" });

    const svc = await getServiceOwnerUserIdByActivity(activity_id);
    if (!svc)
      return res.status(404).json({ message: "Activity not found" });
    const service_user_id = svc.service_user_id;

    // Prevent duplicates
    const insReq = `
      INSERT INTO uniserve.volunteer_requests (activity_id, student_id)
      VALUES (?, ?)
      ON DUPLICATE KEY UPDATE updated_at = CURRENT_TIMESTAMP
    `;
    await new Promise((resolve, reject) => {
      db.query(insReq, [activity_id, studentId], (err) =>
        err ? reject(err) : resolve()
      );
    });

    const student = await getUserBasic(studentId);
    const title = "New Volunteer Request";
    const body = `${student?.full_name || "A student"} wants to volunteer for: ${svc.title}`;
    const payload = JSON.stringify({ activity_id, student_id: studentId });

    const insNotif = `
      INSERT INTO uniserve.notifications
      (type, sender_user_id, receiver_id, activity_id, title, body, payload, status, is_read)
      VALUES ('volunteer_request', ?, ?, ?, ?, ?, ?, 'unread', 0)
    `;
    const notifId = await new Promise((resolve, reject) => {
      db.query(
        insNotif,
        [studentId, service_user_id, activity_id, title, body, payload],
        (err, result) =>
          err ? reject(err) : resolve(result.insertId)
      );
    });

    await sendPushToUser(service_user_id, title, body, {
      notification_id: notifId,
      activity_id,
    });

    res.status(201).json({
      message: "Request sent ",
      notification_id: notifId,
    });
  } catch (e) {
    console.error(" createVolunteerRequest error:", e);
    res.status(500).json({ message: "Server error", error: e.message });
  }
};

/** 3) List notifications for current user */
exports.listMyNotifications = (req, res) => {
  const userId = req.user.id;
  const page = parseInt(req.query.page || "1", 10);
  const limit = parseInt(req.query.limit || "20", 10);
  const offset = (page - 1) * limit;

  const sql = `
    SELECT id, type, sender_user_id, receiver_id, activity_id,
           title, body, payload, status, action, is_read, read_at, acted_at, created_at
    FROM uniserve.notifications
    WHERE receiver_id = ?
    ORDER BY created_at DESC
    LIMIT ? OFFSET ?
  `;
  db.query(sql, [userId, limit, offset], (err, rows) => {
    if (err)
      return res.status(500).json({ message: "DB error", error: err.message });

    const data = rows.map((r) => ({
      id: r.id,
      type: r.type,
      title: r.title,
      body: r.body,
      status: r.status,
      is_read: r.is_read,
      created_at: r.created_at,
      action: r.action,
      read_at: r.read_at,
      acted_at: r.acted_at,
      payload: parseJsonSafe(r.payload),
      meta: {
        sender_user_id: r.sender_user_id,
        receiver_id: r.receiver_id,
        activity_id: r.activity_id,
      },
    }));

    res.json({ data });
  });
};

/** 4) Unread count */
exports.unreadCount = (req, res) => {
  const userId = req.user.id;
  const sql = `
    SELECT COUNT(*) AS cnt
    FROM uniserve.notifications
    WHERE receiver_id = ? AND status = 'unread'
  `;
  db.query(sql, [userId], (err, rows) => {
    if (err)
      return res.status(500).json({ message: "DB error", error: err.message });
    res.json({ unread: rows?.[0]?.cnt ?? 0 });
  });
};

/** 5) Mark as read */
exports.markAsRead = (req, res) => {
  const userId = req.user.id;
  const { id } = req.params;
  const sql = `
    UPDATE uniserve.notifications
    SET status = 'read', is_read = 1, read_at = CURRENT_TIMESTAMP
    WHERE id = ? AND receiver_id = ?
  `;
  db.query(sql, [id, userId], (err, result) => {
    if (err)
      return res.status(500).json({ message: "DB error", error: err.message });
    if (!result.affectedRows)
      return res.status(404).json({ message: "Not found" });
    res.json({ message: "Marked as read " });
  });
};

/** 6) Service center acts on volunteer_request notification */
/*
exports.actOnNotification = async (req, res) => {
  try {
    const serviceUserId = req.user.id;
    const { id } = req.params;
    const { action } = req.body;

    if (!["accept", "reject"].includes(action)) {
      return res.status(400).json({
        message: "action must be accept or reject",
      });
    }

    const notif = await new Promise((resolve, reject) => {
      db.query(
        `SELECT * FROM uniserve.notifications WHERE id = ? AND receiver_id = ? LIMIT 1`,
        [id, serviceUserId],
        (err, rows) => (err ? reject(err) : resolve(rows?.[0] || null))
      );
    });

    if (!notif || notif.type !== "volunteer_request") {
      return res
        .status(404)
        .json({ message: "Notification not found or not actionable" });
    }

    const payloadObj = parseJsonSafe(notif.payload);
    const activity_id = notif.activity_id || payloadObj.activity_id;
    const student_id = payloadObj.student_id || notif.sender_user_id;

    if (!activity_id || !student_id) {
      return res.status(400).json({
        message: "Missing activity_id or student_id in notification payload",
      });
    }

    const newStatus = action === "accept" ? "accepted" : "rejected";
    await new Promise((resolve, reject) => {
      db.query(
        `UPDATE uniserve.volunteer_requests
         SET status = ?, updated_at = CURRENT_TIMESTAMP
         WHERE activity_id = ? AND student_id = ?`,
        [newStatus, activity_id, student_id],
        (err) => (err ? reject(err) : resolve())
      );
    });

    await new Promise((resolve, reject) => {
      db.query(
        `UPDATE uniserve.notifications
         SET status = 'acted', action = ?, acted_at = CURRENT_TIMESTAMP
         WHERE id = ?`,
        [action, id],
        (err) => (err ? reject(err) : resolve())
      );
    });

    const svc = await getUserBasic(serviceUserId);
    const actRow = await new Promise((resolve, reject) => {
      db.query(
        `SELECT title FROM uniserve.services WHERE service_id = ? LIMIT 1`,
        [activity_id],
        (err, rows) =>
          err ? reject(err) : resolve(rows?.[0] || { title: "Activity" })
      );
    });

    const title =
      action === "accept"
        ? "Volunteer Request Accepted"
        : "Volunteer Request Rejected";
    const body = `${svc?.full_name || "The center"} ${
      action === "accept" ? "accepted" : "rejected"
    } your request for: ${actRow.title}`;
    const type =
      action === "accept" ? "request_accepted" : "request_rejected";
    const payloadBack = JSON.stringify({
      activity_id,
      decision_by: serviceUserId,
    });

    const insNotif = `
      INSERT INTO uniserve.notifications
      (type, sender_user_id, receiver_id, activity_id, title, body, payload, status, is_read)
      VALUES (?, ?, ?, ?, ?, ?, ?, 'unread', 0)
    `;
    const backNotifId = await new Promise((resolve, reject) => {
      db.query(
        insNotif,
        [
          type,
          serviceUserId,
          student_id,
          activity_id,
          title,
          body,
          payloadBack,
        ],
        (err, result) =>
          err ? reject(err) : resolve(result.insertId)
      );
    });

    await sendPushToUser(student_id, title, body, {
      notification_id: backNotifId,
      activity_id,
    });

    res.json({ message: `Request ${newStatus} ` });
  } catch (e) {
    console.error(" actOnNotification error:", e);
    res.status(500).json({ message: "Server error", error: e.message });
  }
};

module.exports = {
  registerDeviceToken: exports.registerDeviceToken,
  createVolunteerRequest: exports.createVolunteerRequest,
  listMyNotifications: exports.listMyNotifications,
  unreadCount: exports.unreadCount,
  markAsRead: exports.markAsRead,
  actOnNotification: exports.actOnNotification,
  sendPushToUser,
};
*/
exports.actOnNotification = async (req, res) => {
  try {
    const serviceUserId = req.user.id;
    const { id } = req.params;
    const { action } = req.body;

    if (!["accept", "reject"].includes(action)) {
      return res.status(400).json({
        message: "action must be accept or reject",
      });
    }

    // ===============================
    // 1 جلب الإشعار
    // ===============================
    const notif = await new Promise((resolve, reject) => {
      db.query(
        `SELECT * FROM uniserve.notifications 
         WHERE id = ? AND receiver_id = ? 
         LIMIT 1`,
        [id, serviceUserId],
        (err, rows) => (err ? reject(err) : resolve(rows?.[0] || null))
      );
    });

    if (!notif) {
      return res.status(404).json({
        message: "Notification not found",
      });
    }

    const payload = parseJsonSafe(notif.payload);

    // ===============================
    // 2 تحديد النوع
    // ===============================
    const isVolunteer = notif.type === "volunteer_request";
    const isProposal = notif.type === "service_proposal";

    if (!isVolunteer && !isProposal) {
      return res.status(400).json({
        message: "Notification type is not actionable",
      });
    }

    // ===============================
    // 3 تنفيذ الإجراء
    // ===============================
    let studentId;
    let activityId = null;
    let customRequestId = null;

    if (isVolunteer) {
      activityId = notif.activity_id || payload.activity_id;
      studentId = payload.student_id || notif.sender_user_id;

      if (!activityId || !studentId) {
        return res.status(400).json({
          message: "Missing activity_id or student_id",
        });
      }

      const newStatus = action === "accept" ? "accepted" : "rejected";

      await db.promise().query(
        `UPDATE uniserve.volunteer_requests
         SET status = ?, updated_at = CURRENT_TIMESTAMP
         WHERE activity_id = ? AND student_id = ?`,
        [newStatus, activityId, studentId]
      );
    }

    if (isProposal) {
      customRequestId = payload.custom_request_id;
      studentId = payload.student_user_id || notif.sender_user_id;

      if (!customRequestId || !studentId) {
        return res.status(400).json({
          message: "Missing custom_request_id or student_user_id",
        });
      }

      const newStatus = action === "accept" ? "approved" : "rejected";

      await db.promise().query(
        `UPDATE uniserve.student_custom_requests
         SET status = ?, updated_at = CURRENT_TIMESTAMP
         WHERE id = ?`,
        [newStatus, customRequestId]
      );
    }

    // ===============================
    // 4 تحديث الإشعار الأصلي
    // ===============================
    await db.promise().query(
      `UPDATE uniserve.notifications
       SET status = 'acted',
           action = ?,
           acted_at = CURRENT_TIMESTAMP
       WHERE id = ?`,
      [action, id]
    );

    // ===============================
    // 5 إنشاء إشعار جديد للطالب
    // ===============================
    const title =
      action === "accept"
        ? isVolunteer
          ? "Volunteer Request Accepted"
          : "Service Proposal Accepted"
        : isVolunteer
        ? "Volunteer Request Rejected"
        : "Service Proposal Rejected";

    const body =
      action === "accept"
        ? "Your request has been accepted "
        : "Your request has been rejected ";

    const backPayload = JSON.stringify({
      activity_id: activityId,
      custom_request_id: customRequestId,
      decision_by: serviceUserId,
    });

    const [result] = await db.promise().query(
      `INSERT INTO uniserve.notifications
       (type, sender_user_id, receiver_id, activity_id, title, body, payload, status, is_read)
       VALUES (?, ?, ?, ?, ?, ?, ?, 'unread', 0)`,
      [
        action === "accept" ? "request_accepted" : "request_rejected",
        serviceUserId,
        studentId,
        activityId,
        title,
        body,
        backPayload,
      ]
    );

    await sendPushToUser(studentId, title, body, {
      notification_id: result.insertId,
    });

    res.json({
      message: "Action completed successfully ",
      type: notif.type,
      action,
    });
  } catch (e) {
    console.error(" actOnNotification error:", e);
    res.status(500).json({
      message: "Server error",
      error: e.message,
    });
  }
};
