// 📁 config/permissions.js

const defaultPermissions = {
  // 👤 عامّة
  canViewProfile: false,
  canEditProfile: false,
  canUploadPhoto: false,  // 🆕 رفع صورة الملف الشخصي
canUpdateCustomRequests:false,
  // 🧾 الأنشطة
  canViewActivities: false,
  canAddActivity: false,
  canDeleteActivity: false,
  canApproveActivity: false,
  canManageActivities: false,

  // 💬 الرسائل
  canSendMessages: false,  // 🆕 إرسال الرسائل
  canViewMessages: false,  // 🆕 عرض الرسائل

  // 🎓 الطلاب
  canViewStudents: false,
  canManageStudents: false,

  // 👨‍🏫 الدكاترة
  canViewDoctors: false,
  canManageDoctors: false,

  // 🏢 المراكز (Service Centers)
  canViewCenters: false,
  canManageCenters: false,
  canViewQuestions: false,
  canReplyQuestions: false,

  // ⚙️ الإدارة العامة
  canManageEverything: false,
  canViewStudents: false,
};

// ==================================================
// 🧑‍🎓 الطالب
// ==================================================
const student = {
  ...defaultPermissions,
  canViewProfile: true,
  canEditProfile: true,
  canViewActivities: true,
  canUploadPhoto: true,
  canSendMessages: true,  // ✅ يستطيع إرسال رسائل
  canViewMessages: true,  // ✅ يستطيع عرض الرسائل
  canViewOwnQuestions:true,
};

// ==================================================
// 👨‍🏫 الدكتور
// ==================================================
const doctor = {
  ...defaultPermissions,
  canViewProfile: true,
  canEditProfile: true,
  canViewStudents: true,
  canUploadPhoto: true,
  canSendMessages: true,  // ✅ يستطيع إرسال رسائل
  canViewMessages: true,  // ✅ يستطيع عرض الرسائل
  canViewStudents: true,
  
};

// ==================================================
// 🏢 مركز الخدمة
// ==================================================
const service = {
  ...defaultPermissions,
  canViewProfile: true,
  canEditProfile: true,
  canViewActivities: true,
  canAddActivity: true,
  canDeleteActivity: true,
  canApproveActivity: true,
  canManageActivities: true,
  canUploadPhoto: true,
  canSendMessages: true,  // ✅ يستطيع إرسال رسائل
  canViewMessages: true,  // ✅ يستطيع عرض الرسائل
  canViewStudents:true,
  canViewQuestions: true,
  canReplyQuestions: true,
  canUpdateCustomRequests: true,

};
// ==================================================
// 🛡️ الأدمن (الإدارة)
// ==================================================
const admin = {
  ...defaultPermissions,
  canViewProfile: true,
  canEditProfile: true,
  canUploadPhoto: true,

  // 🎓 الطلاب
  canViewStudents: true,
  canManageStudents: true,   // ربط / إزالة / إدارة

  // 👨‍🏫 الدكاترة
  canViewDoctors: true,
  canManageDoctors: true,

  // 🏢 مراكز الخدمة
  canViewCenters: true,
  canManageCenters: true,

  // 🧾 الأنشطة (اختياري إذا بدك الأدمن يشوف كل شيء)
  canViewActivities: true,
  canManageActivities: true,

  // 💬 الرسائل
  canSendMessages: true,
  canViewMessages: true,

  // ❓ الأسئلة الطلابية
  canViewQuestions: true,
  canReplyQuestions: true,

  // ⚙️ كل الصلاحيات
  canManageEverything: true,
};


// ==================================================
// 🛡️ الأدمن (الإدارة)
// ==================================================


// ==================================================
const permissions = { 
  student, 
  doctor, 
  service, 
  service_center: service,
   admin,


};

module.exports = permissions;
