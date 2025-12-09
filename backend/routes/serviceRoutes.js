const express = require("express");
const router = express.Router();

const verifyToken = require("../middleware/verifyToken");
const MessageController = require("../controllers/messageController");
const upload = require("../middleware/upload");


router.get("/students", verifyToken, serviceController.getCenterStudents);
module.exports = router;