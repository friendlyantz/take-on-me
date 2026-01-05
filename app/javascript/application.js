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
    document.cookie = 'telegram_webview=true; path=/';
  }
});

Rails.start();
