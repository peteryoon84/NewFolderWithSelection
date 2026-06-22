const V = 'v3';
const CACHE = `natrang-${V}`;
const TILES = `natrang-tiles-${V}`;
const CDN   = `natrang-cdn-${V}`;

const SHELL = ['./index.html'];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(SHELL)));
  self.skipWaiting();
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(ks => Promise.all(
      ks.filter(k => ![CACHE, TILES, CDN].includes(k)).map(k => caches.delete(k))
    ))
  );
  self.clients.claim();
});

function networkFirst(cacheName, req) {
  return caches.open(cacheName).then(cache =>
    fetch(req).then(res => {
      if (res.ok) cache.put(req, res.clone());
      return res;
    }).catch(() => cache.match(req).then(r => r || Response.error()))
  );
}

self.addEventListener('fetch', e => {
  const url = new URL(e.request.url);
  if (url.hostname.includes('cartocdn.com') || url.hostname.includes('basemaps')) {
    // tiles: cache-first (offline 우선)
    e.respondWith(
      caches.open(TILES).then(c =>
        c.match(e.request).then(r => r || fetch(e.request).then(res => {
          if (res.ok) c.put(e.request, res.clone());
          return res;
        }))
      )
    );
  } else if (['unpkg.com','cdn.jsdelivr.net','fonts.googleapis.com','fonts.gstatic.com'].some(h => url.hostname.includes(h))) {
    e.respondWith(networkFirst(CDN, e.request));
  } else if (e.request.mode === 'navigate' || url.pathname.endsWith('/') || url.pathname.endsWith('index.html')) {
    // 앱 본문(HTML): 네트워크 우선 → 최신 업데이트 즉시 반영, 오프라인이면 캐시 사용
    e.respondWith(networkFirst(CACHE, e.request));
  } else {
    e.respondWith(caches.match(e.request).then(r => r || fetch(e.request)));
  }
});

// 지도 타일 일괄 저장 요청 처리
self.addEventListener('message', e => {
  if (e.data.type !== 'CACHE_TILES') return;
  const {urls} = e.data;
  const src = e.source;
  caches.open(TILES).then(cache =>
    Promise.all(urls.map(url =>
      fetch(url).then(res => { if (res.ok) cache.put(url, res); }).catch(() => {})
    ))
  ).then(() => {
    if (src) src.postMessage({type: 'TILES_CACHED', count: urls.length});
  });
});
