// controllers/studentProgress.controller.js
const db = require('../db');

exports.getStudentProgress = async (req, res) => {
  try {
    const uniId = String(req.params.studentUniId || '').trim();
    if (!uniId) return res.status(400).json({ message: 'studentUniId is required' });

    // 1) احضار كل الأنشطة المقبولة للطالب مع ساعات النشاط
    const sql = `
      SELECT 
        s.service_id,
        s.title,
        COALESCE(s.progress_points, 0) AS hours,   -- 🔥 اسم أوضح
        vr.updated_at AS accepted_at
      FROM   uniserve.volunteer_requests vr
      JOIN   uniserve.users u ON u.id = vr.student_id
      JOIN   uniserve.services s ON s.service_id = vr.activity_id
      WHERE  u.student_id = ?
        AND  vr.status = 'accepted'
      ORDER BY vr.updated_at DESC
    `;

    const rows = await new Promise((resolve, reject) => {
      db.query(sql, [uniId], (err, r) => (err ? reject(err) : resolve(r || [])));
    });

    // 2) تجهيز العناصر
    const items = rows.map(r => ({
      service_id: r.service_id,
      title: r.title,
      points: Number(r.hours) || 0,   // 🔥 الآن points = ساعات النشاط
      accepted_at: r.accepted_at,
    }));

    // 3) اجمالي الساعات
    let totalHours = items.reduce((sum, it) => sum + it.points, 0);

    // 4) سقف إجمالي الساعات = 50 ساعة
    if (totalHours > 50) totalHours = 50;

    // 5) حساب النسبة للواجهة (progress circle)
    const totalPercent = (totalHours / 50) * 100;

    return res.json({
      student_id: uniId,
      total_hours: totalHours,      // 🔥 أضفت عدد الساعات الحقيقية
      total_percent: totalPercent,  // 🔥 نسبة للـ UI
      items,
    });

  } catch (e) {
    console.error('getStudentProgress error:', e);
    return res.status(500).json({ message: 'Server error', error: e.message });
  }
};
