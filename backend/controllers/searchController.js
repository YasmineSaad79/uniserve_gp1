const db = require("../db");

//  البحث العام (لكل الأدوار)
const globalSearch = async (req, res) => {
  try {
    const { q, role } = req.query;
    if (!q) return res.status(400).json({ error: "Missing search query" });

    let results = [];

    // لو المستخدم طالب
    if (role === "student") {
      const [activities] = await db.promise().query(
        `SELECT 
           service_id AS id,
           title AS name,
           description,
           image_url,
           'activity' AS type
         FROM services 
         WHERE title LIKE ? OR description LIKE ?`,
        [`%${q}%`, `%${q}%`]
      );

      // تنظيف المسار وإرجاع فقط الجزء القابل للوصول
      results = activities.map((a) => ({
        ...a,
        image_url:
          a.image_url && a.image_url.includes("uploads")
            ? "/" + a.image_url.split("uploads").pop()
            : null,
      }));
    }

    //  لو المستخدم مركز خدمة
    else if (role === "service") {
     const [students] = await db.promise().query(
  `SELECT 
     s.student_id,
     u.full_name AS name,
     u.email,
     u.photo_url,
     'student' AS type
   FROM students s
   JOIN users u ON s.user_id = u.id
   WHERE (u.full_name LIKE ? OR u.email LIKE ?)
  `,
  [`%${q}%`, `%${q}%`]
);

      const [activities] = await db.promise().query(
        `SELECT 
           service_id AS id,
           title AS name,
           image_url,
           'activity' AS type
         FROM services 
         WHERE title LIKE ?`,
        [`%${q}%`]
      );


      const cleanedActivities = activities.map((a) => ({
        ...a,
        image_url:
          a.image_url && a.image_url.includes("uploads")
            ? "/" + a.image_url.split("uploads").pop()
            : null,
      }));

      results = [...students, ...cleanedActivities];
    }

    else {
      return res.status(400).json({ error: "Invalid role" });
    }

    res.status(200).json(results);
  } catch (err) {
    console.error(" Search error:", err);
    res.status(500).json({ error: "Internal server error" });
  }
};

module.exports = { globalSearch };
