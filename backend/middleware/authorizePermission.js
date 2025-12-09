// 📁 middleware/authorizePermission.js
const permissions = require("../config/permissions");

module.exports = (permissionKey) => {
  return (req, res, next) => {
    const role = req.user?.role;
    if (!role) {
      return res.status(401).json({ message: "Not authenticated ❌" });
    }

    const rolePermissions = permissions[role];
    if (!rolePermissions || !rolePermissions[permissionKey]) {
      return res.status(403).json({ message: "Access denied ❌" });
    }

    next();
  };
};
