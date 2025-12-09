const express = require("express");
const router = express.Router();
const { aiSearch } = require("../controllers/aiSearchController");
const verifyToken = require("../middleware/verifyToken");

router.post("/query", verifyToken, aiSearch);

module.exports = router;
