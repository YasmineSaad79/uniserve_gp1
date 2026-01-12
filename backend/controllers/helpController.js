// controllers/helpController.js
const db = require("../db");

//  جلب كل الأسئلة الشائعة
exports.getFaqs = async (req, res) => {
  try {
    const [rows] = await db.promise().query("SELECT * FROM faqs ORDER BY id DESC");
    res.status(200).json(rows);
  } catch (err) {
    console.error("Error fetching FAQs:", err);
    res.status(500).json({ error: "Failed to fetch FAQs" });
  }
};

//  (اختياري لاحقًا) إضافة سؤال جديد من لوحة الأدمن أو السنتر
exports.addFaq = async (req, res) => {
  try {
    const { question, answer } = req.body;
    if (!question || !answer)
      return res.status(400).json({ error: "Question and answer are required" });

    await db
      .promise()
      .query("INSERT INTO faqs (question, answer) VALUES (?, ?)", [question, answer]);

    res.status(201).json({ message: "FAQ added successfully" });
  } catch (err) {
    console.error("Error adding FAQ:", err);
    res.status(500).json({ error: "Failed to add FAQ" });
  }
};

exports.submitQuestion = async (req, res) => {
  const { user_id, student_id, question } = req.body;

  if (!user_id || !student_id || !question) {
    return res.status(400).json({ error: "Missing required fields" });
  }

  try {
    await db.promise().query(
      "INSERT INTO student_questions (user_id, student_id, question) VALUES (?, ?, ?)",
      [user_id, student_id, question]
    );

    res.status(201).json({ message: "Question submitted successfully " });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to submit question" });
  }

};

//  رد السنتر على سؤال طالب
exports.replyToQuestion = async (req, res) => {
  const { id } = req.params;
  const { reply } = req.body;

  if (!reply) {
    return res.status(400).json({ error: "Reply content is required" });
  }

  try {
    const [result] = await db
      .promise()
      .query("UPDATE student_questions SET reply = ?, replied_at = NOW() WHERE id = ?", [reply, id]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: "Question not found" });
    }

    res.status(200).json({ message: "Reply sent successfully " });
  } catch (err) {
    console.error(" Error sending reply:", err);
    res.status(500).json({ error: "Server error replying to question" });
  }
};
//  للسنتر: جلب كل أسئلة الطلاب
exports.getAllStudentQuestions = async (req, res) => {
  try {
    const [rows] = await db
      .promise()
      .query("SELECT * FROM student_questions ORDER BY created_at DESC");
    res.json(rows);
  } catch (err) {
    console.error(" Error fetching student questions:", err);
    res.status(500).json({ error: "Server error fetching student questions" });
  }
};

//  للطالب: جلب أسئلته فقط بناءً على studentId
exports.getMyQuestions = async (req, res) => {
  const { studentId } = req.params;

  try {
    const [rows] = await db.promise().query(
      `SELECT id, question, reply, created_at
       FROM student_questions
       WHERE student_id = ?
       ORDER BY created_at DESC`,
      [studentId]
    );
    res.json(rows);
  } catch (err) {
    console.error("Error fetching student questions:", err);
    res.status(500).json({ error: "Server error" });
  }
};
