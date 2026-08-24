importScripts('https://www.gstatic.com/firebasejs/11.9.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/11.9.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyB98R471PcmDyf4mTXvsNNPwXIYtO3otJE',
  authDomain: 'wazuhapp-f04e3.firebaseapp.com',
  projectId: 'wazuhapp-f04e3',
  storageBucket: 'wazuhapp-f04e3.firebasestorage.app',
  messagingSenderId: '583233434705',
  appId: '1:583233434705:web:8378bbfc611856d782f470',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const title = payload.notification?.title || 'Wazuh Alert';
  const options = {
    body: payload.notification?.body || 'New security alert',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
  };
  return self.registration.showNotification(title, options);
});
