// ============================
// backend/controllers/adminRolesController.js
// ============================

const db = require("../db");

// ============================
// Get all roles
// ============================
exports.getAllRoles = async (req, res) => {
  try {
    const [roles] = await db.promise().query(
      "SELECT id, name, description FROM roles ORDER BY name ASC"
    );
    return res.status(200).json(roles);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: "Server error" });
  }
};

// ============================
// Get all permissions
// ============================
exports.getAllPermissions = async (req, res) => {
  try {
    const [permissions] = await db
      .promise()
      .query("SELECT id, key_name, description FROM permissions ORDER BY key_name");

    return res.status(200).json(permissions);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: "Server error" });
  }
};

// ============================
// Get role with permissions
// ============================
exports.getRolePermissions = async (req, res) => {
  try {
    const { roleId } = req.params;

    const [rows] = await db.promise().query(
      `
      SELECT p.id, p.key_name
      FROM role_permissions rp
      JOIN permissions p ON p.id = rp.permission_id
      WHERE rp.role_id = ?
      `,
      [roleId]
    );

    return res.status(200).json(rows);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: "Server error" });
  }
};

// ============================
// Create role + assign permissions
// ============================
// ============================
// Create role + assign permissions (BY NAME ✔️)
// ============================
exports.createRole = async (req, res) => {
  const { name, description, permissions } = req.body;

  if (!name) {
    return res.status(400).json({ message: "Role name is required" });
  }

  try {
    // 1) check role exists
    const [existing] = await db
      .promise()
      .query("SELECT id FROM roles WHERE name = ?", [name]);

    if (existing.length > 0) {
      return res.status(400).json({ message: "Role already exists" });
    }

    // 2) insert role
    const [result] = await db
      .promise()
      .query(
        "INSERT INTO roles (name, description) VALUES (?, ?)",
        [name, description || null]
      );

    const roleId = result.insertId;

    // 3) map permission NAMES → IDs
    if (Array.isArray(permissions) && permissions.length > 0) {
      const [permRows] = await db.promise().query(
        `SELECT id FROM permissions WHERE key_name IN (?)`,
        [permissions]
      );

      if (permRows.length !== permissions.length) {
        return res.status(400).json({
          message: "One or more permissions are invalid",
        });
      }

      const values = permRows.map((p) => [roleId, p.id]);

      await db
        .promise()
        .query(
          "INSERT INTO role_permissions (role_id, permission_id) VALUES ?",
          [values]
        );
    }

    return res.status(201).json({
      message: "Role created successfully",
    });
  } catch (err) {
    console.error("Create role error:", err);
    return res.status(500).json({ message: "Server error" });
  }
};

// ============================
// Update role + permissions (BY NAME ✔️)
// ============================
exports.updateRole = async (req, res) => {
  const { id } = req.params;
  const { name, description, permissions } = req.body;

  if (!name) {
    return res.status(400).json({ message: "Role name is required" });
  }

  try {
    // 1) update role info
    await db.promise().query(
      "UPDATE roles SET name = ?, description = ? WHERE id = ?",
      [name, description || null, id]
    );

    // 2) delete old permissions
    await db.promise().query(
      "DELETE FROM role_permissions WHERE role_id = ?",
      [id]
    );

    // 3) map permission names → ids
    if (Array.isArray(permissions) && permissions.length > 0) {
      const [permRows] = await db.promise().query(
        "SELECT id FROM permissions WHERE key_name IN (?)",
        [permissions]
      );

      if (permRows.length !== permissions.length) {
        return res.status(400).json({
          message: "One or more permissions are invalid",
        });
      }

      const values = permRows.map((p) => [id, p.id]);

      await db.promise().query(
        "INSERT INTO role_permissions (role_id, permission_id) VALUES ?",
        [values]
      );
    }

    return res.status(200).json({
      message: "Role updated successfully",
    });
  } catch (err) {
    console.error("Update role error:", err);
    return res.status(500).json({ message: "Server error" });
  }
};


// ============================
// Delete role
// ============================
exports.deleteRole = async (req, res) => {
  const { id } = req.params;

  try {
    const [users] = await db
      .promise()
      .query("SELECT id FROM users WHERE role_id = ?", [id]);

    if (users.length > 0) {
      return res
        .status(400)
        .json({ message: "Role is assigned to users" });
    }

    await db.promise().query(
      "DELETE FROM role_permissions WHERE role_id = ?",
      [id]
    );
    await db.promise().query("DELETE FROM roles WHERE id = ?", [id]);

    return res.status(200).json({ message: "Role deleted successfully" });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: "Server error" });
  }
};
