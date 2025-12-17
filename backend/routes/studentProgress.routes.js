//  routes/studentProgress.routes.js
'use strict';

const express = require('express');
const router = express.Router();

const verifyToken = require('../middleware/verifyToken');
const authorizePermission = require('../middleware/authorizePermission');
const studentProgressController = require('../controllers/studentProgress.controller');

// ======================================================
//  حماية جميع مسارات تقدّم الطالب
// ======================================================
router.use(verifyToken);

// ======================================================
//  جلب تقدّم الطالب والأنشطة المقبولة
//  Permission: canViewActivities
// ======================================================
router.get(
  '/:studentUniId',
  authorizePermission('canViewActivities'),
  studentProgressController.getStudentProgress
);

module.exports = router;
