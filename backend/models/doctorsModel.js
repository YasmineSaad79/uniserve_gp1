const db = require("../db");

const Doctors = {
  getByUserId: (userId, callback) => {
    db.query(`SELECT * FROM doctors WHERE user_id = ?`, [userId], callback);
  }
};

module.exports = Doctors;
