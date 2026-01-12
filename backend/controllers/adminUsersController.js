// ===============================================
// backend/controllers/adminUsersController.js
// ===============================================

const db = require("../db");

// ============================
// Get all users (with role + status)
// ============================
// ============================
// Get all users (with role + status + photo)
// ============================
exports.getAllUsers = async (req, res) => {
  try {
    const [users] = await db.promise().query(`
      SELECT 
        id,
        full_name,
        email,
        role,
        photo_url,
        is_active,
        created_at
      FROM users
      ORDER BY created_at DESC
    `);

    return res.status(200).json(users);
  } catch (err) {
    console.error("Get users error:", err);
    return res.status(500).json({ message: "Server error" });
  }
};

// ============================
// Deactivate user
// ============================
exports.deactivateUser = async (req, res) => {
  const { userId } = req.params;

  try {
    const [result] = await db.promise().query(
      "UPDATE users SET is_active = 0 WHERE id = ?",
      [userId]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "User not found" });
    }

    return res.status(200).json({
      message: "User deactivated successfully",
    });
  } catch (err) {
    console.error("Deactivate user error:", err);
    return res.status(500).json({ message: "Server error" });
  }
};

// ============================
// Activate user
// ============================
exports.activateUser = async (req, res) => {
  const { userId } = req.params;

  try {
    const [result] = await db.promise().query(
      "UPDATE users SET is_active = 1 WHERE id = ?",
      [userId]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "User not found" });
    }

    return res.status(200).json({
      message: "User activated successfully",
    });
  } catch (err) {
    console.error("Activate user error:", err);
    return res.status(500).json({ message: "Server error" });
  }
};
// ============================
// Change user role (Admin)
// ============================
exports.changeUserRole = async (req, res) => {
  const { userId } = req.params;
  const { role } = req.body;

  if (!role) {
    return res.status(400).json({ message: "Role is required" });
  }

  try {
    // 1) get role id by name
    const [roles] = await db
      .promise()
      .query("SELECT id FROM roles WHERE name = ?", [role]);

    if (roles.length === 0) {
      return res.status(400).json({ message: "Invalid role name" });
    }

    const roleId = roles[0].id;

    // 2) update user role
    const [result] = await db
      .promise()
      .query(
        "UPDATE users SET role_id = ? WHERE id = ?",
        [roleId, userId]
      );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "User not found" });
    }

    return res.status(200).json({
      message: "User role updated successfully",
      data: {
        userId,
        role,
      },
    });
  } catch (err) {
    console.error("Change role error:", err);
    return res.status(500).json({ message: "Server error" });
  }
};
