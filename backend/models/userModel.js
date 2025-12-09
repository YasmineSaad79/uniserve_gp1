const db = require("../db");

const Users = {
  create: (fullName, email, password, role, callback) => {
    const sql = `
      INSERT INTO users (full_name, email, password, role)
      VALUES (?, ?, ?, ?)
    `;
    db.query(sql, [fullName, email, password, role], callback);
  },

  getByEmail: (email, callback) => {
    db.query(`SELECT * FROM users WHERE email = ?`, [email], callback);
  },

  getById: (id, callback) => {
    db.query(`SELECT * FROM users WHERE id = ?`, [id], callback);
  },

  updatePhoto: (id, photoUrl, callback) => {
    db.query(`UPDATE users SET photo_url = ? WHERE id = ?`,
      [photoUrl, id], callback);
  },

  updateFCMToken: (id, token, callback) => {
    db.query(`UPDATE users SET fcm_token = ? WHERE id = ?`,
      [token, id], callback);
  }
};

module.exports = Users;
