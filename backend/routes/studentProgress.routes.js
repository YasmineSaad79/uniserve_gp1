// routes/studentProgress.routes.js
'use strict';

const express = require('express');
const router = express.Router();

const verifyToken = require('../middleware/verifyToken');
const studentProgressController = require('../controllers/studentProgress.controller');

// ✅ نحمي جميع المسارات الخاصة بالطلاب
router.use(verifyToken);

/**
 * @route   GET /api/student/progress/:studentUniId
 * @desc    Get student's overall progress and accepted activities
 * @access  Private (Student)
 */
router.get('/:studentUniId', studentProgressController.getStudentProgress);

module.exports = router;
