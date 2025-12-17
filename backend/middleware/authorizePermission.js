//  middleware/authorizePermission.js

module.exports = (permissionKey) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ message: "Not authenticated " });
    }

    const permissions = req.user.permissions; //  جاية من DB

    if (!permissions || !permissions.includes(permissionKey)) {
      return res.status(403).json({
        message: `Access denied Missing permission: ${permissionKey}`,
      });
    }

    next();
  };
};
