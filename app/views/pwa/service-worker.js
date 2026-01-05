console.log('Service worker loaded.');

self.addEventListener("push", async (event) => {
  const { title, options } = await event.data.json()
  event.waitUntil(self.registration.showNotification(title, options))
})

self.addEventListener("notificationclick", function(event) {
  event.notification.close()
  event.waitUntil(
    clients.matchAll({ type: "window" }).then((clientList) => {
      const path = event.notification.data?.path || '/'
      
      // Check if app is already open
      for (let i = 0; i < clientList.length; i++) {
        let client = clientList[i]
        let clientPath = (new URL(client.url)).pathname

        if (clientPath == path && "focus" in client) {
          return client.focus()
        }
      }

      // Open new window/tab
      if (clients.openWindow) {
        return clients.openWindow(path)
      }
    })
  )
})
