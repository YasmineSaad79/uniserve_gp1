// ============================================================

const db = require('../db');

/** إحضار تقويم شهر محدّد (الأنشطة المقبولة فقط) */
async function getCalendarByMonth(req, res) {
  try {
    const uniId = String(req.params.studentUniId || '').trim();
    const year  = Number(req.query.year);
    const month = Number(req.query.month);

    if (!uniId || !year || !month) {
      return res.status(400).json({ message: 'studentUniId, year, month are required' });
    }
    if (month < 1 || month > 12) {
      return res.status(400).json({ message: 'invalid month' });
    }

    // حدود الشهر كنصوص تواريخ
    const daysInMonth  = new Date(year, month, 0).getDate();
    const mm           = String(month).padStart(2, '0');
    const startOfMonth = `${year}-${mm}-01`;
    const endOfMonth   = `${year}-${mm}-${String(daysInMonth).padStart(2, '0')}`;

    const sql = `
      SELECT 
        s.service_id,
        s.title,
        COALESCE(s.progress_points, 0) AS points,
        DATE_FORMAT(s.end_date, '%Y-%m-%d') AS due_date_str,
        vr.updated_at AS accepted_at
      FROM uniserve.volunteer_requests vr
      JOIN uniserve.users    u ON u.id = vr.student_id
      JOIN uniserve.services s ON s.service_id = vr.activity_id
      WHERE u.student_id = ?
        AND vr.status = 'accepted'
        AND s.end_date BETWEEN ? AND ?
      ORDER BY s.end_date ASC
    `;

    const rows = await new Promise((resolve, reject) => {
      db.query(sql, [uniId, startOfMonth, endOfMonth], (err, r) => {
        if (err) return reject(err);
        resolve(r || []);
      });
    });

    // تجميع حسب اليوم: 'YYYY-MM-DD' -> [items]
    const itemsByDay = {};
    for (const r of rows) {
      const key = r.due_date_str; // نص جاهز من MySQL
      if (!itemsByDay[key]) itemsByDay[key] = [];
      itemsByDay[key].push({
        service_id : r.service_id,
        title      : r.title,
        points     : Number(r.points) || 0,
        due_date   : r.due_date_str,     // نحتفظ به كنص (بدون TZ)
        accepted_at: r.accepted_at,
      });
    }

    return res.json({
      student_id  : uniId,
      year,
      month,
      items_by_day: itemsByDay,
    });
  } catch (e) {
    console.error('getCalendarByMonth error:', e);
    return res.status(500).json({ message: 'Server error', error: e.message });
  }
}

/** إحضار كل الأنشطة المقبولة مجمّعة حسب end_date (لكل السنوات) */
async function getCalendarAll(req, res) {
  try {
    const uniId = String(req.params.studentUniId || '').trim();
    if (!uniId) {
      return res.status(400).json({ message: 'studentUniId is required' });
    }

    const sql = `
      SELECT 
        s.service_id,
        s.title,
        COALESCE(s.progress_points, 0) AS points,
        DATE_FORMAT(s.end_date, '%Y-%m-%d') AS due_date_str,
        vr.updated_at AS accepted_at
      FROM uniserve.volunteer_requests vr
      JOIN uniserve.users    u ON u.id = vr.student_id
      JOIN uniserve.services s ON s.service_id = vr.activity_id
      WHERE u.student_id = ?
        AND vr.status = 'accepted'
        AND s.end_date IS NOT NULL
      ORDER BY s.end_date ASC
    `;

    const rows = await new Promise((resolve, reject) => {
      db.query(sql, [uniId], (err, r) => {
        if (err) return reject(err);
        resolve(r || []);
      });
    });

    const itemsByDate = {};
    let first = null;
    let last  = null;

    for (const r of rows) {
      const key = r.due_date_str; // نص ثابت
      if (!itemsByDate[key]) itemsByDate[key] = [];
      itemsByDate[key].push({
        service_id : r.service_id,
        title      : r.title,
        points     : Number(r.points) || 0,
        due_date   : r.due_date_str,
        accepted_at: r.accepted_at,
      });

      // نطاق التواريخ كنصوص (بدون إنشاء Date)
      if (!first || key < first) first = key;
      if (!last  || key > last ) last  = key;
    }

    return res.json({
      student_id   : uniId,
      total_days   : Object.keys(itemsByDate).length,
      range        : { start: first, end: last },
      items_by_date: itemsByDate,
    });
  } catch (e) {
    console.error('getCalendarAll error:', e);
    return res.status(500).json({ message: 'Server error', error: e.message });
  }
}

module.exports = {
  getCalendarByMonth,
  getCalendarAll,
};
