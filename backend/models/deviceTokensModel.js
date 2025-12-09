const db = require("../db");

const DeviceTokens = {
  save: (userId, token, platform, callback) => {
    const sql = `
      INSERT INTO device_tokens (user_id, token, platform)
      VALUES (?, ?, ?)
      ON DUPLICATE KEY UPDATE token = VALUES(token), platform = VALUES(platform)
    `;
    db.query(sql, [userId, token, platform], callback);
  },

  getByUser: (userId, callback) => {
    db.query(`SELECT * FROM device_tokens WHERE user_id = ?`, [userId], callback);
  }
};

module.exports = DeviceTokens;
