const db = require("../db");

const Center = {
  getServiceCenter: (centerId, callback) => {
    db.query(`SELECT * FROM center WHERE center_id = ?`, [centerId], callback);
  }
};

module.exports = Center;
