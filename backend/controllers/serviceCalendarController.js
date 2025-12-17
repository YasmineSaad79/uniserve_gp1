// controllers/serviceCalendarController.js

const db = require("../db").promise();

// ================== GET ACTIVITIES FOR CALENDAR ==================
exports.getCalendarActivities = async (req, res) => {
  try {
    const userId = req.user.id;

    const [rows] = await db.query(
      `SELECT 
          service_id AS activity_id,
          title,
          start_date,
          end_date
       FROM services
       WHERE created_by = ?`,
      [userId]
    );

    return res.json(rows);
  } catch (err) {
    console.error(" Calendar SQL Error:", err);
    return res.status(500).json({ message: err.message });
  }
};



// ================== ADD REMINDER ==================
exports.addReminder = async (req, res) => {
  try {
    const userId = req.user.id;
    const { activity_id, remind_date, note } = req.body;

    const [result] = await db.query(
      `INSERT INTO reminders (center_id, activity_id, remind_date, note, created_at)
       VALUES (?, ?, ?, ?, NOW())`,
      [userId, activity_id, remind_date, note]
    );

    return res.status(201).json({ message: "Reminder added", id: result.insertId });
  } catch (err) {
    console.error(" Reminder SQL Error:", err);
    return res.status(500).json({ message: err.message });
  }
};
