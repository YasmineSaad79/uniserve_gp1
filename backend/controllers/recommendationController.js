const db = require("../db");

// ============================
//  AI-Based Simple Recommendations
// ============================
exports.getRecommendations = async (req, res) => {
  try {
    const studentId = req.params.studentId;

    // 1 fetch preferences + hobbies
    const [studentRows] = await db
      .promise()
      .query(
        `
        SELECT preferences, hobbies , user_id 
        FROM students 
        WHERE student_id = ?
        `,
        [studentId]
      );

    if (!studentRows.length) {
      return res.status(404).json({ message: "Student not found" });
    }

    const prefs = (studentRows[0].preferences || "").toLowerCase();
    const hobbies = (studentRows[0].hobbies || "").toLowerCase();
    const text = `${prefs} ${hobbies}`;

    // 2 fetch all services
    const [services] = await db
      .promise()
      .query(
        `
        SELECT 
          service_id,
          title,
          description
        FROM services
        WHERE status = 'active'
        `
      );

    // 3 scoring system
    let scores = {};
    services.forEach((s) => (scores[s.service_id] = 1));

    const rules = [
      {
        keywords: ["help", "مساعدة", "يتيم", "orphans", "orphan"],
        serviceIds: [3], // orphan sponsoring
        score: 5,
      },
      {
        keywords: ["medical", "طب", "دم", "blood", "hospital"],
        serviceIds: [1], // blood donation
        score: 5,
      },
      {
        keywords: ["field", "خارج", "ميداني", "outdoor"],
        serviceIds: [2], // field volunteering
        score: 5,
      },
      {
        keywords: ["donation", "تبرع", "book", "كتب"],
        serviceIds: [4], // donation book
        score: 4,
      },
    ];

    // apply scoring rules
    rules.forEach((rule) => {
      const matched = rule.keywords.some((k) => text.includes(k));
      if (matched) {
        rule.serviceIds.forEach((id) => {
          if (scores[id] != null) {
            scores[id] += rule.score;
          }
        });
      }
    });

    // 4 reduce score for services already done
    const [history] = await db
      .promise()
      .query(
        `
        SELECT activity_id 
        FROM volunteer_requests 
        WHERE student_id = ? AND status = 'accepted'
        `,
        [studentId]
      );

    history.forEach((h) => {
      if (scores[h.activity_id] != null) {
        scores[h.activity_id] -= 2; // reduce repetition
      }
    });

    // 5 sort by score
    const sorted = services
      .map((s) => ({
        service_id: s.service_id,
        service_title: s.title,
        description: s.description,
        score: scores[s.service_id] || 0,
      }))
      .sort((a, b) => b.score - a.score)
      .slice(0, 3);

    return res.json({ recommendations: sorted });
  } catch (error) {
    console.error(" Recommendation error:", error);
    return res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
};
