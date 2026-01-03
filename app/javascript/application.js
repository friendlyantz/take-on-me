// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "credential"
import "messenger"

import "chartkick"
import "Chart.bundle"

import Rails from "@rails/ujs";


function registerServiceWorker() {
  console.log('Registering service worker...');

  window.addEventListener('load', () => {
    navigator.serviceWorker.register('/service-worker.js').then((registration) => {
      console.log('Service worker registered:', registration);
    }).catch((error) => {
      console.error('Service worker registration failed:', error);
    });
  });
}

if ('serviceWorker' in navigator) {
  registerServiceWorker();
}

Rails.start();
