// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "credential"
import "messenger"

import "chartkick"
import "Chart.bundle"

import Rails from "@rails/ujs";

// Detect Telegram WebView and set a cookie
document.addEventListener('DOMContentLoaded', () => {
  const isTelegramAndroid = navigator.userAgent.includes('Android') && typeof TelegramWebview !== 'undefined';
  const isTelegramIOS = navigator.userAgent.includes('iPhone') && typeof TelegramWebviewProxy !== 'undefined';
  if (isTelegramAndroid || isTelegramIOS) {
    // Set cookie or fetch('/detect_webview', { headers: { 'X-Telegram-Webview': 'true' } })
    document.cookie = 'telegram_webview=true; path=/';
    // Or prompt: window.open(location.href, '_blank'); for full browser
  }
});


function registerServiceWorker() {
  console.log('Registering service worker...');

  navigator.serviceWorker.register('/service-worker.js')
    .then((registration) => {
      console.log('Service worker registered:', registration);
      return navigator.serviceWorker.ready;
    })
    .then(async (serviceWorkerRegistration) => {
      console.log('Service worker ready');
      console.log('Push manager:', serviceWorkerRegistration.pushManager);
      
      // Check for existing subscription
      const existingSub = await serviceWorkerRegistration.pushManager.getSubscription();
      console.log('Existing subscription:', existingSub);
      
      if (existingSub) {
        console.log('Already subscribed, sending to server');
        await sendSubscriptionToServer(existingSub);
        return;
      }

      // Check permission state
      const permissionState = await serviceWorkerRegistration.pushManager.permissionState({
        userVisibleOnly: true,
        applicationServerKey: window.vapidPublicKey
      });
      console.log('Permission state:', permissionState);

      // Request permission if needed
      const permission = await Notification.requestPermission();
      console.log('Notification permission:', permission);
      
      if (permission !== 'granted') {
        console.warn('Notification permission denied');
        return;
      }

      // Subscribe
      console.log('Attempting to subscribe...');
      console.log('VAPID key length:', window.vapidPublicKey?.length);
      
      const sub = await serviceWorkerRegistration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: window.vapidPublicKey
      });
      
      console.log('Subscription successful:', sub);
      await sendSubscriptionToServer(sub);
    })
    .catch((error) => {
      console.error('Error details:');
      console.error('  Name:', error.name);
      console.error('  Message:', error.message);
      console.error('  Stack:', error.stack);
    });
}

async function sendSubscriptionToServer(sub) {
  try {
    const data = await fetch('/web_push_notifications', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify(sub)
    }).then(response => response.json());

    console.log('Push subscription sent to server:', data);
  } catch (error) {
    console.error('Failed to send subscription to server:', error);
  }
}

if ('serviceWorker' in navigator) {
  registerServiceWorker();
}

Rails.start();
