importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey:            "AIzaSyDnMjA7ivJAeI1J94ofWRyi7-sBznR1F-0",
  appId:             "1:1083285864321:web:c4817436e9c7be5923f280",
  messagingSenderId: "1083285864321",
  projectId:         "study-docs-cloud",
  authDomain:        "study-docs-cloud.firebaseapp.com",
  storageBucket:     "study-docs-cloud.firebasestorage.app",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const { title, body } = payload.notification;
  self.registration.showNotification(title, {
    body: body,
    icon: "/icons/Icon-192.png",
  });
});
