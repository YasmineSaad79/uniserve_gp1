// routes/studentRequests.js
const express = require('express');
const router = express.Router();
const verifyToken = require('../middleware/verifyToken');
const controller = require('../controllers/studentRequestsController');

// كل المسارات محمية
router.use(verifyToken);

// POST   /api/student/requests               (إرسال اقتراح جديد + إشعار للمركز)
router.post('/', controller.createRequest);

// GET    /api/student/requests/:studentId    (studentId = رقم الجامعة String)
router.get('/:studentId', controller.getRequestsByStudent);

// PATCH  /api/student/requests/:id/status    (id = request_id) موافقة/رفض + إشعار للطالب
router.patch('/:id/status', controller.updateRequestStatus);

module.exports = router;
