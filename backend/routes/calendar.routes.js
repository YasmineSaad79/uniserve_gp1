// routes/calendar.routes.js
const express = require('express');
const router = express.Router();

const verifyToken = require('../middleware/verifyToken');
const calendarController = require('../controllers/calendar.controller');


router.get('/calendar/month/:studentUniId', verifyToken, calendarController.getCalendarByMonth);
router.get('/calendar/all/:studentUniId',   verifyToken, calendarController.getCalendarAll);

module.exports = router;
