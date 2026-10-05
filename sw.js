// offline cache: the app works without internet once opened
const CACHE = 'profile-nc-v28';
const MODELS = 'profile-models-v1';   // segmentation runtime + model: large, versioned URLs, kept across app updates
const MODEL_HOSTS = ['cdn.jsdelivr.net', 'storage.googleapis.com'];
const FILES = ['./', 'index.html', 'jspdf.umd.min.js', 'manifest.webmanifest', 'icon-180.png', 'icon-192.png', 'icon-512.png'];
self.addEventListener('install', e => { e.waitUntil(caches.open(CACHE).then(c => c.addAll(FILES)).then(() => self.skipWaiting())); });
self.addEventListener('activate', e => { e.waitUntil(caches.keys().then(ks => Promise.all(ks.filter(k => k !== CACHE && k !== MODELS).map(k => caches.delete(k)))).then(() => self.clients.claim())); });
self.addEventListener('fetch', e => {
  if (e.request.method !== 'GET') return;
  const url = new URL(e.request.url);
  if (MODEL_HOSTS.includes(url.hostname)) {
    // cache first: download once, then work offline
    e.respondWith(caches.open(MODELS).then(c => c.match(e.request).then(m => m || fetch(e.request).then(r => { if (r.ok) c.put(e.request, r.clone()); return r; }))));
    return;
  }
  if (url.origin !== location.origin) return;
  // network first for the page (so updates arrive), cache fallback offline
  e.respondWith(fetch(e.request).then(r => { if (r.ok) { const cp = r.clone(); caches.open(CACHE).then(c => c.put(e.request, cp)); } return r; })
    .catch(() => caches.match(e.request, {ignoreSearch: true}).then(m => m || caches.match('index.html'))));
});
