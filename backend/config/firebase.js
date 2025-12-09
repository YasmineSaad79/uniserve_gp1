// backend/config/firebase.js
const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

const servicePath = path.join(__dirname, 'firebase-service-account.json');
if (!fs.existsSync(servicePath)) {
  throw new Error(
    `Missing firebase-service-account.json at: ${servicePath}\n` +
    `Place your Firebase service account key there.`
  );
}

if (!admin.apps.length) {
  const serviceAccount = require(servicePath);
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

module.exports = admin;
