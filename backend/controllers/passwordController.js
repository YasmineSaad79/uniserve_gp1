// File: controllers/passwordController.js

const db = require("../db");
const bcrypt = require('bcrypt'); // مكتبة التشفير

// دالة لمعالجة طلب تغيير كلمة السر
exports.changePassword = async (req, res) => {
    const { email, oldPassword, newPassword, confirmPassword } = req.body;

    // التحقق من وجود كل الحقول المطلوبة
    if (!email || !oldPassword || !newPassword || !confirmPassword) {
        return res.status(400).json({ message: "Please provide all fields ❌" });
    }

    // التحقق من تطابق كلمة السر الجديدة مع التأكيد
    if (newPassword !== confirmPassword) {
        return res.status(400).json({ message: "New password and confirmation do not match ❌" });
    }
    
    // التحقق من طول كلمة السر الجديدة
    if (newPassword.length < 6) {
        return res.status(400).json({ message: "New password must be at least 6 characters ❌" });
    }

    const sqlSelect = "SELECT password FROM users WHERE email = ?";
    
    db.query(sqlSelect, [email], async (err, results) => {
        if (err) {
            console.error("❌ Database error:", err);
            return res.status(500).json({ message: "Database error ❌" });
        }

        if (results.length === 0) {
            return res.status(404).json({ message: "User not found ❌" });
        }

        const hashedPassword = results[0].password;
        console.log("Inputted Password:", oldPassword);
        console.log("Hashed Password from DB:", hashedPassword);

        // ✅ التحقق من كلمة السر القديمة: استخدام bcrypt.compare للمقارنة الآمنة
        const isMatch = await bcrypt.compare(oldPassword, hashedPassword);
        
        if (!isMatch) {
            return res.status(401).json({ message: "Old password is incorrect ❌" });
        }

        try {
            // ✅ تشفير كلمة السر الجديدة قبل تخزينها
            const saltRounds = 10;
            const newHashedPassword = await bcrypt.hash(newPassword, saltRounds);
            
            const sqlUpdate = "UPDATE users SET password = ? WHERE email = ?";
            
            db.query(sqlUpdate, [newHashedPassword, email], (err2) => {
                if (err2) {
                    console.error("❌ Failed to update password:", err2);
                    return res.status(500).json({ message: "Failed to update password ❌" });
                }

                return res.status(200).json({ message: "Password updated successfully ✅" });
            });
        } catch (hashError) {
             console.error("❌ Failed to hash new password:", hashError);
             return res.status(500).json({ message: "Failed to process new password ❌" });
        }
    });
};