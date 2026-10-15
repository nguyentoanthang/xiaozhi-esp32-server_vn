/* global self, workbox */

// Custom handling logic for Service Worker installation and activation
self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
});

// CDN resource list
const CDN_CSS = [
  'https://unpkg.com/element-ui@2.15.14/lib/theme-chalk/index.css',
  'https://cdnjs.cloudflare.com/ajax/libs/normalize/8.0.1/normalize.min.css'
];

const CDN_JS = [
  'https://unpkg.com/vue@2.6.14/dist/vue.min.js',
  'https://unpkg.com/vue-router@3.6.5/dist/vue-router.min.js',
  'https://unpkg.com/vuex@3.6.2/dist/vuex.min.js',
  'https://unpkg.com/element-ui@2.15.14/lib/index.js',
  'https://unpkg.com/axios@0.27.2/dist/axios.min.js',
  'https://unpkg.com/opus-decoder@0.7.7/dist/opus-decoder.min.js'
];

// Runs automatically once the manifest is injected into the Service Worker
const manifest = self.__WB_MANIFEST || [];

// Check whether CDN mode is enabled
const isCDNEnabled = manifest.some(entry => 
  entry.url === 'cdn-mode' && entry.revision === 'enabled'
);

console.log(`Service Worker initialized, CDN mode: ${isCDNEnabled ? 'enabled' : 'disabled'}`);

// Inject workbox-related code
importScripts('https://storage.googleapis.com/workbox-cdn/releases/7.0.0/workbox-sw.js');
workbox.setConfig({ debug: false });

// Enable workbox
workbox.core.skipWaiting();
workbox.core.clientsClaim();

// Precache the offline page
const OFFLINE_URL = '/offline.html';
workbox.precaching.precacheAndRoute([
  { url: OFFLINE_URL, revision: null }
]);

// Add an install-complete event handler that shows an install message in the console
self.addEventListener('install', event => {
  if (isCDNEnabled) {
    console.log('Service Worker installed, starting to cache CDN resources');
  } else {
    console.log('Service Worker installed, CDN mode disabled, caching local resources only');
  }
  
  // Make sure the offline page is cached
  event.waitUntil(
    caches.open('offline-cache').then((cache) => {
      return cache.add(OFFLINE_URL);
    })
  );
});

// Add an activate event handler
self.addEventListener('activate', event => {
  console.log('Service Worker activated and now controlling the page');
  
  // Clean up old version caches
  event.waitUntil(
    caches.keys().then(cacheNames => {
      return Promise.all(
        cacheNames.filter(cacheName => {
          // Clean up caches other than the current version
          return cacheName.startsWith('workbox-') && !workbox.core.cacheNames.runtime.includes(cacheName);
        }).map(cacheName => {
          return caches.delete(cacheName);
        })
      );
    })
  );
});

// Add a fetch event interceptor to see whether CDN resources hit the cache
self.addEventListener('fetch', event => {
  // Only monitor the CDN resource cache when CDN mode is enabled
  if (isCDNEnabled) {
    const url = new URL(event.request.url);
    
    // For CDN resources, log whether they hit the cache
    if ([...CDN_CSS, ...CDN_JS].includes(url.href)) {
      // Do not interfere with the normal fetch flow, only add logging
      console.log(`Requesting CDN resource: ${url.href}`);
    }
  }
});

// Cache CDN resources only in CDN mode
if (isCDNEnabled) {
  // Cache CDN CSS resources
  workbox.routing.registerRoute(
    ({ url }) => CDN_CSS.includes(url.href),
    new workbox.strategies.CacheFirst({
      cacheName: 'cdn-stylesheets',
      plugins: [
        new workbox.expiration.ExpirationPlugin({
          maxAgeSeconds: 365 * 24 * 60 * 60, // increased to 1 year of caching
          maxEntries: 10, // cache at most 10 CSS files
        }),
        new workbox.cacheableResponse.CacheableResponsePlugin({
          statuses: [0, 200], // cache successful responses
        }),
      ],
    })
  );

  // Cache CDN JS resources
  workbox.routing.registerRoute(
    ({ url }) => CDN_JS.includes(url.href),
    new workbox.strategies.CacheFirst({
      cacheName: 'cdn-scripts',
      plugins: [
        new workbox.expiration.ExpirationPlugin({
          maxAgeSeconds: 365 * 24 * 60 * 60, // increased to 1 year of caching
          maxEntries: 20, // cache at most 20 JS files
        }),
        new workbox.cacheableResponse.CacheableResponsePlugin({
          statuses: [0, 200], // cache successful responses
        }),
      ],
    })
  );
}

// Cache local static resources regardless of whether CDN mode is enabled
workbox.routing.registerRoute(
  /\.(?:js|css|png|jpg|jpeg|svg|gif|ico|woff|woff2|eot|ttf|otf)$/,
  new workbox.strategies.StaleWhileRevalidate({
    cacheName: 'static-resources',
    plugins: [
      new workbox.expiration.ExpirationPlugin({
        maxAgeSeconds: 7 * 24 * 60 * 60, // 7 days of caching
        maxEntries: 50, // cache at most 50 files
      }),
    ],
  })
);

// Cache HTML pages
workbox.routing.registerRoute(
  /\.html$/,
  new workbox.strategies.NetworkFirst({
    cacheName: 'html-cache',
    plugins: [
      new workbox.expiration.ExpirationPlugin({
        maxAgeSeconds: 1 * 24 * 60 * 60, // 1 day of caching
        maxEntries: 10, // cache at most 10 HTML files
      }),
    ],
  })
);

// Offline page - use a more reliable approach
workbox.routing.setCatchHandler(async ({ event }) => {
  // Return an appropriate default page based on the request type
  switch (event.request.destination) {
    case 'document':
      // If it is a page request, return the offline page
      return caches.match(OFFLINE_URL);
    default:
      // Return an error for all other requests
      return Response.error();
  }
}); 