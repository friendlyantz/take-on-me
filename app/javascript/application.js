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

      navigator.serviceWorker.ready
      .then((serviceWorkerRegistration) => {
        serviceWorkerRegistration.pushManager
        .subscribe({
          userVisibleOnly: true,
          applicationServerKey: window.vapidPublicKey
        })
        .then(function(sub) {
           window.myGlobalSub = sub; 
           console.log('Service worker is ready and push subscription initiated. Subscription:', sub); 
           console.log(
            // TODO: Remove in production. Save this to your server to send push notifications.
            'Subscription (JSON):',
            JSON.parse(JSON.stringify(sub)) 
           );
          })
      })
    })
    .catch((error) => {
      console.error('Service worker registration failed:', error);
    });
}

if ('serviceWorker' in navigator) {
  registerServiceWorker();
}

Rails.start();
