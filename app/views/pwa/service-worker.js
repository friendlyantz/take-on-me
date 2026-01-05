const VERSION = 'v20260104'; // Version will be the key, increment to invalidate old caches
console.log('Service worker loaded. Version:', VERSION);

async function networkFirst(request) {
  const cache = await caches.open(VERSION);
  
  try {
    const responseFromNetwork = await fetch(request.clone());
    
    if (responseFromNetwork.ok) {
      cache.put(request, responseFromNetwork.clone());
    }
    
    return responseFromNetwork;
  } catch (error) {
    const cachedResponse = await cache.match(request);
    
    if (cachedResponse) {
      return cachedResponse;
    }
    
    return new Response('Network error happened', {
      status: 408,
      headers: { 'Content-Type': 'text/plain' },
    });
  }
}

async function cacheFirst(request) {
  const cache = await caches.open(VERSION);
  const cachedResponse = await caches.match(request);

  if (cachedResponse) {
    return cachedResponse;
  }

  try {
    const responseFromNetwork = await fetch(request.clone());

    cache.put(request, responseFromNetwork.clone());

    return responseFromNetwork;
  } catch (error) {
    return new Response('Network error happened', {
      status: 408,
      headers: { 'Content-Type': 'text/plain' },
    });
  }
}

function isNavigationRequest(request) {
  return request.mode === 'navigate';
}

function isAPIRequest(request) {
  return request.url.includes('/api/') || request.url.includes('.json');
}

self.addEventListener('fetch', function(event) {
  // Use network-first for HTML pages (navigation requests) so Turbo streams work
  if (isNavigationRequest(event.request)) {
    event.respondWith(networkFirst(event.request));
  }
  // Use cache-first for static assets and other resources
  else {
    event.respondWith(cacheFirst(event.request));
  }
});

self.addEventListener('activate', function(event) {
  event.waitUntil(
    caches.keys().then(function(cacheNames) {
      return Promise.all(
        cacheNames.map(function(cacheName) {
          if (cacheName !== VERSION) {
            return caches.delete(cacheName);
          }
        })
      );
    })
  );
});
// Add a service worker for processing Web Push notifications:
//
// self.addEventListener("push", async (event) => {
//   const { title, options } = await event.data.json()
//   event.waitUntil(self.registration.showNotification(title, options))
// })
//
// self.addEventListener("notificationclick", function(event) {
//   event.notification.close()
//   event.waitUntil(
//     clients.matchAll({ type: "window" }).then((clientList) => {
//       for (let i = 0; i < clientList.length; i++) {
//         let client = clientList[i]
//         let clientPath = (new URL(client.url)).pathname
//
//         if (clientPath == event.notification.data.path && "focus" in client) {
//           return client.focus()
//         }
//       }
//
//       if (clients.openWindow) {
//         return clients.openWindow(event.notification.data.path)
//       }
//     })
//   )
// })
