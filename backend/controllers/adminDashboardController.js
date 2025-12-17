const db = require("../db");

// Helper: handle date range
function getDateRangeQuery(range) {
  switch (range) {
    case "today":
      return "AND DATE(created_at) = CURDATE()";
    case "7d":
      return "AND created_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)";
    case "30d":
      return "AND created_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)";
    case "year":
      return "AND YEAR(created_at) = YEAR(CURDATE())";
    default:
      return "";
  }
}


// ===============================
//  Admin Dashboard (Premium)
// ===============================
exports.getAdminDashboard = async (req, res) => {
  try {
    let { range, start, end } = req.query;

    let dateFilter = "";

    // Custom date range
    if (start && end) {
      dateFilter = `AND DATE(created_at) BETWEEN '${start}' AND '${end}'`;
    } else {
      dateFilter = getDateRangeQuery(range);
    }

    // =============== 1) KPIs ===============
    const [[students]] = await db
      .promise()
      .query("SELECT COUNT(*) AS total FROM users WHERE role='student'");

    const [[studentsPrev]] = await db
      .promise()
      .query(
        "SELECT COUNT(*) AS total FROM users WHERE role='student' AND created_at < DATE_SUB(CURDATE(), INTERVAL 30 DAY)"
      );

    const [[doctors]] = await db
      .promise()
      .query("SELECT COUNT(*) AS total FROM users WHERE role='doctor'");

    const [[services]] = await db
      .promise()
      .query("SELECT COUNT(*) AS total FROM services");

    const [[requests]] = await db
      .promise()
      .query(
        `SELECT COUNT(*) AS total FROM volunteer_requests WHERE 1=1 ${dateFilter}`
      );

    const [[requestsPrev]] = await db
      .promise()
      .query(
        `SELECT COUNT(*) AS total FROM volunteer_requests 
       WHERE created_at < DATE_SUB(CURDATE(), INTERVAL 30 DAY)`
      );

    // Growth Calculation
    const calcGrowth = (current, previous) => {
      if (previous === 0) return current > 0 ? 100 : 0;
      return Math.round(((current - previous) / previous) * 100);
    };

    const requestsGrowth = calcGrowth(
      requests.total,
      requestsPrev.total
    );

    // =============== 2) Students per Service ===============
 const [studentsPerService] = await db.promise().query(
  `
  SELECT s.title AS service, COUNT(v.student_id) AS total
  FROM services s
  LEFT JOIN volunteer_requests v 
      ON v.activity_id = s.service_id 
      AND v.status='accepted'
      ${dateFilter.replace(/created_at/g, "v.created_at")}
  GROUP BY s.service_id
  ORDER BY total DESC
  `
);


    // =============== 3) Request Status ===============
  const [statusRows] = await db.promise().query(
  `
    SELECT status, COUNT(*) AS total
    FROM volunteer_requests
    WHERE 1=1 ${dateFilter}
    GROUP BY status
  `
);


      

    const requestStatus = { pending: 0, accepted: 0, rejected: 0 };
    statusRows.forEach((r) => (requestStatus[r.status] = r.total));

    // =============== 4) Messages per Day ===============
      const [messagesDaily] = await db.promise().query(
  `
    SELECT DATE(sent_at) AS date, COUNT(*) AS total
    FROM messages
    WHERE 1=1 ${dateFilter.replace(/created_at/g, "sent_at")}
    GROUP BY DATE(sent_at)
    ORDER BY date ASC
  `
);



    // =============== 5) Top Doctors ===============
    const [topDoctors] = await db
      .promise()
      .query(
        `
      SELECT u.full_name AS doctor, COUNT(sd.student_user_id) AS students
      FROM users u
      JOIN student_doctor sd ON sd.doctor_user_id = u.id
      WHERE u.role='doctor'
      GROUP BY u.id
      ORDER BY students DESC
      LIMIT 5
    `
      );

    // =============== 6) Activity Log ===============
  const [activityLog] = await db
  .promise()
  .query(
    `
      SELECT text, time FROM (
          SELECT 
            CONCAT(full_name, ' registered') AS text,
            created_at AS time
          FROM users
          ORDER BY created_at DESC
          LIMIT 5
      ) AS T
    `
  );


    return res.status(200).json({
      // KPIs
      total_students: students.total,
      total_doctors: doctors.total,
      total_services: services.total,
      total_requests: requests.total,

      // Growth
      requests_growth: requestsGrowth,

      // Charts
      students_per_service: studentsPerService,
      request_status: requestStatus,
      messages_daily: messagesDaily,

      // Rankings
      top_doctors: topDoctors,

      // Recent Activity
      activity_log: activityLog,
    });
  } catch (err) {
    console.error(" Admin Dashboard Error:", err);
    return res.status(500).json({ error: "Server error" });
  }
};
