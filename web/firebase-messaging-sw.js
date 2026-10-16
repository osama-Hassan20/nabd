importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');

// Overwrite these values with your actual Firebase web config from Firebase Console
firebase.initializeApp({
 apiKey: "AIzaSyC6TJEizLLedEalyMDkE5_dxgFM1ZpKNaQ",
  authDomain: "abdullah5-933e4.firebaseapp.com",
  projectId: "abdullah5-933e4",
  messagingSenderId: "928164534865",
  appId: "1:928164534865:web:19546ffc123d69ef6f3670",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('Received background message: ', payload);
  const { title, body } = payload.data || {};
  self.registration.showNotification(title || 'Darsi Admin', {
    body: body || '',
    icon: '/icons/Icon-192.png',
    data: payload.data,
  });
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const targetUrl = event.notification.data?.click_action || '/teachers';
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        if ('focus' in client) return client.focus();
      }
      if (clients.openWindow) return clients.openWindow(targetUrl);
    })
  );
});
