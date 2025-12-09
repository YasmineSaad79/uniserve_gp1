// File: routes/password.route.js

const express = require("express");
const router = express.Router();
const passwordController = require("../controllers/passwordController"); // استدعاء ملف Controller الجديد

router.put("/", passwordController.changePassword);

module.exports = router;
