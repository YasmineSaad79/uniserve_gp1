// ============================
// backend/routes/adminRolesRoutes.js
// ============================

const express = require("express");
const router = express.Router();

const adminRolesController = require("../controllers/adminRolesController");
const verifyToken = require("../middleware/verifyToken");
const authorizePermission = require("../middleware/authorizePermission");

// Roles
router.get(
  "/admin/roles",
  verifyToken,
  authorizePermission("canManageEverything"),
  adminRolesController.getAllRoles
);

router.post(
  "/admin/roles",
  verifyToken,
  authorizePermission("canManageEverything"),
  adminRolesController.createRole
);

router.put(
  "/admin/roles/:id",
  verifyToken,
  authorizePermission("canManageEverything"),
  adminRolesController.updateRole
);

router.delete(
  "/admin/roles/:id",
  verifyToken,
  authorizePermission("canManageEverything"),
  adminRolesController.deleteRole
);

// Permissions
router.get(
  "/admin/permissions",
  verifyToken,
  authorizePermission("canManageEverything"),
  adminRolesController.getAllPermissions
);

router.get(
  "/admin/roles/:roleId/permissions",
  verifyToken,
  authorizePermission("canManageEverything"),
  adminRolesController.getRolePermissions
);

module.exports = router;
