import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["banner", "toggle"]

  async connect() {
    // Check if this device is already subscribed
    const isSubscribed = await this.checkIfThisDeviceIsSubscribed()
    
    // Update toggle state if present
    if (this.hasToggleTarget) {
      this.toggleTarget.checked = isSubscribed
    }
    
    // Show/hide banner
    if (isSubscribed) {
      this.removeBanner()
    } else {
      this.showBanner()
    }
  }

  async toggle(event) {
    const checkbox = event.target
    
    if (checkbox.checked) {
      console.log('Toggle: subscribing...')
      await this.subscribe()
    } else {
      console.log('Toggle: unsubscribing...')
      await this.unsubscribe()
    }
  }

  async checkIfThisDeviceIsSubscribed() {
    if (!('serviceWorker' in navigator)) return false
    
    try {
      const registration = await navigator.serviceWorker.getRegistration()
      if (!registration) return false
      
      const subscription = await registration.pushManager.getSubscription()
      return !!subscription
    } catch (error) {
      console.error('Error checking subscription:', error)
      return false
    }
  }

  showBanner() {
    if (this.hasBannerTarget) {
      this.bannerTarget.classList.remove('hidden')
    }
  }

  removeBanner() {
    if (this.hasBannerTarget) {
      this.bannerTarget.remove()
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
        this.removeBanner()
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
      this.removeBanner()
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

  async unsubscribe() {
    try {
      const registration = await navigator.serviceWorker.getRegistration()
      if (!registration) return

      const subscription = await registration.pushManager.getSubscription()
      if (!subscription) return

      // Unsubscribe from browser
      await subscription.unsubscribe()
      console.log('Unsubscribed from push notifications')

      // Remove from server
      await fetch('/web_push_notifications/unsubscribe', {
        method: 'DELETE',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify(subscription)
      })
    } catch (error) {
      console.error('Unsubscribe error:', error)
    }
  }

  dismiss() {
    // Hide for 7 days
    const expires = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toUTCString()
    document.cookie = `push_notification_dismissed=true; expires=${expires}; path=/`
    this.removeBanner()
  }

  removeBanner() {
    if (this.hasBannerTarget) {
      this.bannerTarget.remove()
    }
  }

  showBanner() {
    if (this.hasBannerTarget) {
      this.bannerTarget.classList.remove('hidden')
    }
  }
}
