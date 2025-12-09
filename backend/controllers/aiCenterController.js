// controllers/aiCenterController.js
const db = require("../db");

/* ============================================================
    HELPER FUNCTIONS — TOKENIZING + VECTORIZATION + SIMILARITY
============================================================ */

function tokenize(text) {
  if (!text) return [];

  return text
    .toLowerCase()
    .replace(/[^a-zA-Z0-9\u0600-\u06FF\s]/g, " ") // يدعم العربي + الإنجليزي
    .split(/\s+/)
    .filter((w) => w.length > 2); // تجاهل الكلمات الصغيرة
}

function textToVector(text, vocab) {
  const tokens = tokenize(text);
  const vec = new Array(vocab.length).fill(0);

  tokens.forEach((t) => {
    const idx = vocab.indexOf(t);
    if (idx !== -1) vec[idx] += 1;
  });

  return vec;
}

function cosineSimilarity(v1, v2) {
  let dot = 0,
    norm1 = 0,
    norm2 = 0;

  for (let i = 0; i < v1.length; i++) {
    dot += v1[i] * v2[i];
    norm1 += v1[i] * v1[i];
    norm2 += v2[i] * v2[i];
  }

  if (!norm1 || !norm2) return 0;

  return dot / (Math.sqrt(norm1) * Math.sqrt(norm2));
}

/* ============================================================
     MAIN CONTROLLER — CUSTOM REQUEST SIMILARITY ANALYSIS
============================================================ */

exports.analyzeCustomRequestSimilarity = async (req, res) => {
  const centerUserId = req.user.id; // من التوكن
  const requestId = req.params.requestId;

  try {
    const dbp = db.promise();

    /* -------------------------------------------
       1) جلب بيانات الطلب من student_custom_requests
    -------------------------------------------- */
    const [reqRows] = await dbp.query(
      `
      SELECT scr.request_id,
             scr.title,
             scr.description,
             scr.status,
             scr.student_id
      FROM student_custom_requests scr
      WHERE scr.request_id = ?
      `,
      [requestId]
    );

    if (!reqRows.length) {
      return res.status(404).json({ message: "Request not found" });
    }

    const request = reqRows[0];
    const requestText = `${request.title} ${request.description}`.trim();


    /* -------------------------------------------
       2) جلب كل الخدمات التي أنشأها هذا المركز
    -------------------------------------------- */
    const [serviceRows] = await dbp.query(
      `
      SELECT service_id, title, description
      FROM services
      WHERE created_by = ?
      `,
      [centerUserId]
    );

    if (!serviceRows.length) {
      return res.json({
        request,
        matches: [],
        message: "This center has no services yet.",
      });
    }


    /* -------------------------------------------
       3) بناء Vocabulary من الطلب + الخدمات
    -------------------------------------------- */
    const allTexts = [
      requestText,
      ...serviceRows.map((s) => `${s.title} ${s.description}`),
    ];

    const vocabSet = new Set();
    allTexts.forEach((txt) => {
      tokenize(txt).forEach((t) => vocabSet.add(t));
    });

    const vocab = Array.from(vocabSet);
    const reqVec = textToVector(requestText, vocab);


    /* -------------------------------------------
       4) حساب التشابه مع كل خدمة باستخدام Cosine
    -------------------------------------------- */
    const matches = serviceRows.map((s) => {
      const serviceText = `${s.title} ${s.description}`.trim();
      const serviceVec = textToVector(serviceText, vocab);
      const sim = cosineSimilarity(reqVec, serviceVec);

      let level = "low";
      if (sim >= 0.70) level = "high";
      else if (sim >= 0.40) level = "medium";

      return {
        service_id: s.service_id,
        title: s.title,
        description: s.description,
        similarity: sim, // بين 0 و 1
        level,
      };
    });

    /* -------------------------------------------
       5) ترتيب النتائج وإرجاع أعلى 3
    -------------------------------------------- */
    matches.sort((a, b) => b.similarity - a.similarity);

    return res.json({
      request,
      matches: matches.slice(0, 3),
    });

  } catch (err) {
    console.error("❌ AI similarity error:", err);
    return res.status(500).json({ message: "AI similarity error occurred" });
  }
};
