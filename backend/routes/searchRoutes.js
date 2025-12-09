// 📁 routes/searchRoutes.js
const express = require("express");
const router = express.Router();
const { globalSearch } = require("../controllers/searchController");

// 🟣 مسار البحث العام
router.get("/", globalSearch);

module.exports = router;