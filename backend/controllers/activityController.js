const db = require('../db');
const fs = require('fs');
const path = require('path');

//  تحويل تاريخ ISO إلى تنسيق MySQL
const formatForMySQL = (isoDate) => {
  if (!isoDate) return null;
  const date = new Date(isoDate);
  return date.toISOString().slice(0, 19).replace('T', ' ');
};

// ===================================================
// 1. جلب كل الأنشطة
// ===================================================
exports.getAllActivities = (req, res) => {
  const query = "SELECT * FROM services";

  db.query(query, (err, results) => {
    if (err) {
      console.error(" Error fetching activities:", err);
      return res.status(500).json({ success: false, message: "Database error" });
    }

    const formattedResults = results.map(activity => {
      if (activity.image_url) {
        const idx = activity.image_url.indexOf("uploads/");
        if (idx !== -1) activity.image_url = activity.image_url.substring(idx);
      }

      if (activity.form_template_path) {
        const idx = activity.form_template_path.indexOf("uploads/");
        if (idx !== -1) activity.form_template_path = activity.form_template_path.substring(idx);
      }

      activity.id = activity.service_id;
      delete activity.service_id;

      return activity;
    });

    res.status(200).json({ success: true, data: formattedResults });
  });
};

// ===================================================
// 2. جلب نشاط واحد حسب ID
// ===================================================
exports.getActivityById = (req, res) => {
  const { id } = req.params;
  const query = "SELECT * FROM services WHERE service_id = ?";

  db.query(query, [id], (err, results) => {
    if (err) {
      console.error(" Error fetching activity:", err);
      return res.status(500).json({ success: false, message: "Database error" });
    }

    if (results.length === 0) {
      return res.status(404).json({ success: false, message: "Activity not found" });
    }

    const activity = results[0];

    if (activity.image_url) {
      const idx = activity.image_url.indexOf("uploads/");
      if (idx !== -1) activity.image_url = activity.image_url.substring(idx);
    }

    if (activity.form_template_path) {
      const idx = activity.form_template_path.indexOf("uploads/");
      if (idx !== -1) activity.form_template_path = activity.form_template_path.substring(idx);
    }

    activity.id = activity.service_id;
    delete activity.service_id;

    res.status(200).json(activity);
  });
};

// ===================================================
// 3. إضافة نشاط جديد
// ===================================================
exports.addActivity = (req, res) => {
  const { title, description, location, created_by, start_date, end_date, status } = req.body;

  const imagePath =
    req.files?.image?.[0]?.filename ? "uploads/" + req.files.image[0].filename : "uploads/default.jpg";

  const formPath =
    req.files?.form?.[0]?.filename ? "uploads/" + req.files.form[0].filename : null;

  if (!title || !description || !location || !created_by || !start_date || !end_date) {
    return res.status(400).json({ success: false, message: "Missing required fields." });
  }

  const sql = `
    INSERT INTO services 
    (title, description, location, created_by, start_date, end_date, status, image_url, form_template_path) 
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
  `;

  const values = [
    title,
    description,
    location,
    created_by,
    formatForMySQL(start_date),
    formatForMySQL(end_date),
    status || "pending",
    imagePath,
    formPath,
  ];

  db.query(sql, values, (err, result) => {
    if (err) {
      console.error(" Error adding activity:", err);
      return res.status(500).json({ success: false, message: "Database insert error." });
    }

    res.status(201).json({
      success: true,
      message: "Activity added successfully.",
      activityId: result.insertId,
      imagePath,
      formPath,
    });
  });
};

// ===================================================
// 4. تحديث نشاط
// ===================================================
exports.updateActivity = (req, res) => {
  const { id } = req.params;
  const {
    title,
    description,
    location,
    created_by,
    start_date,
    end_date,
    status,
  } = req.body;

  //  إذا تم رفع ملفات جديدة
  const imagePath = req.files?.image?.[0]?.filename
    ? "uploads/" + req.files.image[0].filename
    : undefined;

  const formPath = req.files?.form?.[0]?.filename
    ? "uploads/" + req.files.form[0].filename
    : undefined;

  const fields = {
    title,
    description,
    location,
    created_by,
    start_date: start_date ? formatForMySQL(start_date) : undefined,
    end_date: end_date ? formatForMySQL(end_date) : undefined,
    status,
    image_url: imagePath,
    form_template_path: formPath,
  };

  const keys = Object.keys(fields).filter((k) => fields[k] !== undefined);
  if (keys.length === 0) {
    return res
      .status(400)
      .json({ success: false, message: "No data provided for update." });
  }

  const updateQuery = `
    UPDATE services 
    SET ${keys.map((k) => `${k} = ?`).join(", ")}, updated_at = NOW()
    WHERE service_id = ?
  `;

  const updateValues = keys.map((k) => fields[k]);
  updateValues.push(id);

  db.query(updateQuery, updateValues, (err, result) => {
    if (err) {
      console.error(" Error updating activity:", err);
      return res
        .status(500)
        .json({ success: false, message: "Database update error." });
    }

    if (result.affectedRows === 0) {
      return res
        .status(404)
        .json({ success: false, message: "Activity not found." });
    }

    res
      .status(200)
      .json({ success: true, message: "Activity updated successfully." });
  });
};


// ===================================================
// 5. حذف نشاط
// ===================================================
exports.deleteActivity = (req, res) => {
  const { id } = req.params;

  const findSql = "SELECT image_url FROM services WHERE service_id = ?";
  db.query(findSql, [id], (findErr, result) => {
    if (findErr || result.length === 0) {
      return res.status(404).json({ success: false, message: "Activity not found." });
    }

    const imagePath = result[0].image_url;

    const deleteSql = "DELETE FROM services WHERE service_id = ?";
    db.query(deleteSql, [id], (err, result) => {
      if (err) {
        console.error(" Error deleting activity:", err);
        return res.status(500).json({ success: false, message: "Database delete error." });
      }

      //  حذف الصورة من المجلد
      if (imagePath && imagePath !== "uploads/default.jpg") {
        const fullPath = path.join(__dirname, '..', imagePath);
        if (fs.existsSync(fullPath)) {
          fs.unlinkSync(fullPath);
          console.log(` Deleted file: ${imagePath}`);
        }
      }

      res.status(200).json({ success: true, message: "Activity deleted successfully." });
    });
  });
};
