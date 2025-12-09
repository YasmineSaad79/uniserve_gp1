const db = require("../db");
const fetch = (...args) =>
  import("node-fetch").then(({ default: fetch }) => fetch(...args));
const stringSimilarity = require("string-similarity");

// ===============================================
// 🤖 AI Search Controller (Role-based Intelligent Search)
// ===============================================
exports.aiSearch = async (req, res) => {
  try {
    const { q } = req.body;
    if (!q) return res.status(400).json({ error: "Missing query text" });

    // ✅ استخراج الدور من التوكن
    const userRole = req.user?.role || "student";
    console.log("🎭 ROLE RECEIVED FROM TOKEN:", userRole);

    console.log(`🎭 AI Search started by role: ${userRole}`);

    // ==========================================
    // 1️⃣ جلب البيانات من قاعدة البيانات
    // ==========================================
    const [activities] = await db
      .promise()
      .query("SELECT service_id AS id, title, description, image_url FROM services");

    let students = [];
    let doctors = [];

    // 👨‍🏫 الدكتور → الأنشطة + الطلاب
    if (userRole === "doctor") {
      [students] = await db
        .promise()
        .query(`
          SELECT u.id, u.full_name AS title, u.email AS description, u.photo_url AS image_url
          FROM users u
          JOIN students s ON u.id = s.user_id
        `);
      console.log("👨‍🏫 Doctor role: searching activities + students");
    }

    // 🏢 مركز الخدمة → الأنشطة + الطلاب + دكاترة
   // 🏢 مركز الخدمة → الأنشطة + الطلاب + دكاترة
if (["service", "service_center", "center"].includes(userRole.toLowerCase())) {
  console.log("📥 Fetching students & doctors for service center...");

  [students] = await db
    .promise()
    .query(`
      SELECT u.id, u.full_name AS title, u.email AS description, u.photo_url AS image_url
      FROM users u
      JOIN students s ON u.id = s.user_id
    `);
  console.log("👩‍🎓 Students count:", students.length);

  [doctors] = await db
    .promise()
    .query(`
      SELECT id, full_name AS title, email AS description, photo_url AS image_url
      FROM users
      WHERE role = 'doctor'
    `);
  console.log("👨‍⚕️ Doctors count:", doctors.length);
}


    // ✅ دمج البيانات حسب الدور
  // ✅ دمج البيانات حسب الدور
let combinedList = [...activities.map(a => ({ ...a, type: "activity" }))];

if (userRole === "doctor") {
  combinedList = [
    ...combinedList,
    ...students.map(s => ({ ...s, type: "student" })),
  ];
}

if (["service", "service_center", "center"].includes(userRole.toLowerCase())) {
  combinedList = [
    ...combinedList,
    ...students.map(s => ({ ...s, type: "student" })),
    ...doctors.map(d => ({ ...d, type: "doctor" })),
  ];
}


    if (combinedList.length === 0)
      return res.status(404).json({ message: "No data available for search." });

    // ==========================================
    // 2️⃣ بناء Prompt للذكاء الاصطناعي
    // ==========================================
    const listText = combinedList
      .map(
        (a, i) => `${i + 1}. [${a.type}] ${a.title} — ${a.description || "No description"}`
      )
      .join("\n");

    const prompt = `
You are an AI assistant that helps match user queries with the most relevant community service data.

Here is the available data:
${listText}

The user is searching for: "${q}"

Rules:
- If the role is "student", only suggest [activity].
- If the role is "doctor", you can also include [student].
- If the role is "service", you can include [student] and [doctor].
- Respond only with valid JSON (no markdown, no text), like:
[
  {"title": "match title", "reason": "short reason why it matches"}
]
`;

    // ==========================================
    // 3️⃣ استدعاء Ollama
    // ==========================================
    const ollamaRes = await fetch("http://127.0.0.1:11434/api/generate", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        model: "llama3",
        prompt,
        stream: false,
      }),
    });

    const data = await ollamaRes.json();
    let text = data.response?.trim() || "";

    if (text.startsWith("```")) text = text.replace(/```json|```/g, "").trim();

    // ==========================================
    // 4️⃣ تحليل استجابة الذكاء
    // ==========================================
    let parsedResults;
    try {
      parsedResults = JSON.parse(text);
    } catch {
      const match = text.match(/\[[\s\S]*\]/);
      parsedResults = match
        ? JSON.parse(match[0])
        : [{ title: "Parsing error", reason: text.slice(0, 200) }];
    }

    if (!Array.isArray(parsedResults)) parsedResults = [parsedResults];

    // ==========================================
    // 5️⃣ المطابقة الذكية
    // ==========================================
    const allItems = combinedList; // جاهزة بأنواعها

    let matched = [];
    allItems.forEach((item) => {
      parsedResults.forEach((r) => {
        const cleanTitle = r.title?.toLowerCase().split("—")[0].trim() || "";
        const itemTitle = item.title.toLowerCase();
        const similarity = stringSimilarity.compareTwoStrings(itemTitle, cleanTitle);

        if (
          itemTitle.includes(cleanTitle) ||
          cleanTitle.includes(itemTitle) ||
          similarity > 0.55
        ) {
          matched.push({
            id: item.id,
            title: item.title,
            description: item.description,
            image_url: item.image_url,
            reason: r.reason || `Related to "${cleanTitle}"`,
            similarity: similarity.toFixed(2),
            type: item.type,
          });
        }
      });
    });

    // fallback في حال لم يوجد تطابق
   // 🧠 fallback أذكى — فحص يدوي للأسماء إذا الذكاء ما وجد شيء
if (matched.length === 0) {
  console.log("⚠️ No AI matches, trying local name similarity...");

  // فحص يدوي إذا المستخدم كتب اسم شخص
  const allItemsLower = allItems.map(item => ({
    ...item,
    titleLower: item.title.toLowerCase(),
  }));
  const queryLower = q.toLowerCase();

  const nameMatches = allItemsLower
    .map(item => ({
      ...item,
      similarity: stringSimilarity.compareTwoStrings(item.titleLower, queryLower),
    }))
    .filter(item => item.similarity > 0.45)
    .sort((a, b) => b.similarity - a.similarity);

  if (nameMatches.length > 0) {
    console.log(`✅ Local name match found: ${nameMatches[0].title}`);
    matched = nameMatches.map(item => ({
      id: item.id,
      title: item.title,
      description: item.description,
      image_url: item.image_url,
      reason: `Name similar to "${q}"`,
      similarity: item.similarity.toFixed(2),
      type: item.type,
    }));
  } else {
    // آخر خيار fallback
    matched.push({
      id: allItems[0].id,
      title: allItems[0].title,
      description: allItems[0].description,
      image_url: allItems[0].image_url,
      reason: parsedResults[0]?.reason || `AI suggestion (no match found)`,
      similarity: "N/A",
      type: allItems[0].type,
    });
  }
}


    // ==========================================
    // 6️⃣ الرد النهائي
    // ==========================================
    console.log(`✅ ${matched.length} results matched for [${userRole}] role`);
    return res.json({
      query: q,
      role: userRole,
      ai_response: parsedResults,
      matches: matched,
    });
  } catch (err) {
    console.error("❌ AI Search Error:", err);
    res.status(500).json({ error: "AI semantic search failed" });
  }
};
