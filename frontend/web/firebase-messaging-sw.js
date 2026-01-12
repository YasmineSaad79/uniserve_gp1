importScripts("https://www.gstatic.com/firebasejs/9.6.11/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.6.11/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyBFWs4Q-00AjNt32EGivL6i_tRuIqDOFkI",
  authDomain: "uniserve-67027.firebaseapp.com",
  projectId: "uniserve-67027",
  storageBucket: "uniserve-67027.firebasestorage.app",
  messagingSenderId: "575576735035",
  appId: "1:575576735035:web:b646786ff7de30a14c8b1e",
  measurementId: "G-SHSN7Y3Y1X",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((msg) => {
  console.log("🌙 Background Message:", msg);

  const title =
    msg.notification?.title ||
    msg.data?.title ||
    "New Notification";

  const body =
    msg.notification?.body ||
    msg.data?.body ||
    "";

  self.registration.showNotification(title, {
    body: body,
    icon: "/icons/icon-192.png", // اختياري
  });
});

