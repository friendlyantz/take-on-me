import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["banner"]

  connect() {
    // Auto-register if user already granted permission
    if ('serviceWorker' in navigator && window.vapidPublicKey) {
      this.checkExistingSubscription()
    }
  }

  async checkExistingSubscription() {
    try {
      const registration = await navigator.serviceWorker.getRegistration()
      if (!registration) return

      const existingSub = await registration.pushManager.getSubscription()
      if (existingSub) {
        await this.sendSubscriptionToServer(existingSub)
      }
    } catch (error) {
      console.error('Error checking subscription:', error)
    }
  }

  async subscribe() {
    if (!('serviceWorker' in navigator)) {
      alert('Push notifications are not supported in this browser')
      return
    }

    if (!window.vapidPublicKey) {
      console.error('VAPID public key not found')
      return
    }

    try {
      // Register service worker
      const registration = await navigator.serviceWorker.register('/service-worker.js')
      await navigator.serviceWorker.ready

      // Check for existing subscription
      const existingSub = await registration.pushManager.getSubscription()
      if (existingSub) {
        await this.sendSubscriptionToServer(existingSub)
        this.hideBanner()
        return
      }

      // Request permission
      const permission = await Notification.requestPermission()
      console.log('Notification permission:', permission)
      
      if (permission !== 'granted') {
        console.warn('Notification permission denied')
        return
      }

      // Subscribe
      const sub = await registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: window.vapidPublicKey
      })
      
      console.log('Subscription successful:', sub)
      await this.sendSubscriptionToServer(sub)
      this.hideBanner()
    } catch (error) {
      console.error('Subscription error:', error)
      alert('Failed to subscribe to notifications. Please try again.')
    }
  }

  async sendSubscriptionToServer(sub) {
    try {
      const response = await fetch('/web_push_notifications', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify(sub)
      })

      if (response.ok) {
        console.log('Subscription sent to server')
      }
    } catch (error) {
      console.error('Failed to send subscription to server:', error)
    }
  }

  dismiss() {
    // Hide for 7 days
    const expires = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toUTCString()
    document.cookie = `push_notification_dismissed=true; expires=${expires}; path=/`
    this.hideBanner()
  }

  hideBanner() {
    if (this.hasBannerTarget) {
      this.bannerTarget.remove()
    }
  }
}
