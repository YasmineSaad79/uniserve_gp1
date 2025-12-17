// ===============================================
//  backend/server.js (الكود المدمج والنهائي)
// ===============================================
require("dotenv").config();
const express = require("express");
const cors = require("cors");
const path = require("path");
const db = require("./db");

const userRoutes = require("./routes/userRoutes");
const profileRoutes = require("./routes/profileRoutes");
const studentProfileRoutes = require("./routes/studentProfileRoutes");
const changePasswordRoutes = require("./routes/changePasswordRoutes");
const doctorRoutes = require("./routes/doctorRoutes");
const aiSearchRoutes = require("./routes/aiSearchRoutes");
const studentRoutes = require("./routes/all_studentRoute.js"); 
const messageRoutes = require("./routes/messageRoutes"); 
const searchRoutes = require("./routes/searchRoutes");
const serviceRoutes = require("./routes/serviceProfileRoutes");
const serviceStudentRoutes = require("./routes/all_studentRoute"); 
const studentProgressRoutes = require('./routes/studentProgress.routes');
const helpRoutes = require("./routes/helpRoutes");
const adminActivitiesRoutes = require("./routes/adminActivitiesRoutes");
const submissionRoutes = require("./routes/submissionRoutes");
const recommendationRoutes = require("./routes/recommendationRoutes");
const aiCenterRoutes = require("./routes/aiCenterRoutes");


const serviceCalendarRoutes = require("./routes/serviceCalendarRoutes");

const app = express();
const PORT = process.env.PORT || 5000;

//  Middleware (البرمجيات الوسيطة)

app.use(cors());

app.use(express.json());
app.use(express.urlencoded({ extended: true })); // مهم للتعامل مع البيانات المرسلة من النماذج (Forms/PUT requests)
app.use("/api/ai", aiSearchRoutes);
app.use("/api/ai", aiCenterRoutes);
//  Routes (التوجيه) - تجميع جميع المسارات تحت /api
app.use("/api/users", userRoutes); // تسجيل الدخول/الخروج/إعادة تعيين كلمة المرور
app.use("/api/profile", profileRoutes); // إدارة بروفايل المستخدمين
app.use("/api/student", studentProfileRoutes); // مسارات خاصة ببروفايل الطلاب
app.use("/api/change-password", changePasswordRoutes); // تغيير كلمة المرور
app.use("/api/doctor", doctorRoutes); // مسارات خاصة بالأطباء/المشرفين
app.use("/api/service", serviceRoutes);
app.use("/api/help", helpRoutes);
app.use("/api", recommendationRoutes);
// مسارات إضافية من الكود الثاني
app.use("/api", studentRoutes); // هذا المسار قد يكون /api/students أو مسار عام آخر، سأبقيه كما هو لعدم وجود معلومات كافية عنه
app.use("/api/messages", messageRoutes); // مسارات إدارة الرسائل
app.use("/api/hours", require("./routes/hoursRoutes"));

//  خدمة الملفات الثابتة (للوصول إلى صور الـ uploads)
app.use("/uploads", express.static(path.join(__dirname, "uploads")));
app.use('/uploads', express.static('uploads'));
app.use("/api/search", searchRoutes);
app.use("/api/users", adminActivitiesRoutes);
app.use("/api/service", serviceCalendarRoutes);
app.use("/api/admin", require("./routes/adminRoutes"));


app.use('/api/student/requests', require('./routes/studentRequests'));
app.use('/api/activities', require('./routes/activityRoutes'));

app.use('/api/notifications', require('./routes/notificationsRoutes'));
app.use('/api/student/progress', studentProgressRoutes);
app.use('/api', require('./routes/calendar.routes'));
app.use("/api/requests", require("./routes/requestsRoutes"));
app.use("/uploads", express.static(path.join(__dirname, "uploads")));
app.use("/api/submissions", submissionRoutes);


//  اختبار الاتصال بقاعدة البيانات
db.connect((err) => {
  if (err) {
    console.error(" Database connection failed:", err);
  } else {
    console.log(" Connected to MySQL database successfully!");
  }
});

//  اختبار السيرفر
app.get("/", (req, res) => {
  res.send(" Server is running and ready!");
});

//  تشغيل السيرفر
app.listen(PORT, () => {
  console.log(`🚀 Server is running on http://localhost:${PORT}`);
});
