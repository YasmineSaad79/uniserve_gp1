// node update-password-only.js
const bcrypt = require('bcryptjs');
const db = require('./db'); // تأكدي إن هذا الملف يصدّر connection أو pool

const userEmail = 'yays2025w@gmail.com';
const newPassword = 'shA@12345678'; // ← حطّي هنا كلمة السر الحقيقية
const saltRounds = 10;

bcrypt.hash(newPassword, saltRounds, (err, hash) => {
  if (err) {
    console.error('Hash error', err);
    process.exit(1);
  }

  console.log('Generated hash:', hash);

  const sql = 'UPDATE users SET password = ? WHERE email = ?';
  db.query(sql, [hash, userEmail], (dbErr, result) => {
    if (dbErr) {
      console.error('DB update error:', dbErr);
      process.exit(1);
    }
    console.log('DB result:', result); // طباعة كل شيء لفحص affectedRows
    if (result.affectedRows === 0) {
      console.log('No user found with that email (or no permissions).');
    } else {
      console.log('Password updated successfully for', userEmail);
    }
    process.exit(0);
  });
});
