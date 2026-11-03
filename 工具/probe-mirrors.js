// 探测 GitHub 二进制资源的可达镜像（objects.githubusercontent.com 在本机被墙）
const https = require('https');
const http = require('http');

const TARGET = 'https://github.com/microsoft/WSL/releases/download/3.0.3/wsl.3.0.3.0.x64.msi';
const MIRRORS = [
  'https://ghfast.top/' + TARGET,
  'https://gh-proxy.com/' + TARGET,
  'https://ghproxy.net/' + TARGET,
  'https://hub.gitmirror.com/' + TARGET,
  'https://ghp.ci/' + TARGET,
  'https://cors.isteed.cc/' + TARGET,
  TARGET,
];

function probe(url, redirects = 0) {
  return new Promise((resolve) => {
    if (redirects > 5) return resolve({ url, status: 'REDIRECT_LOOP' });
    const mod = url.startsWith('http://') ? http : https;
    const req = mod.request(url, { method: 'HEAD', headers: { 'User-Agent': 'Mozilla/5.0' }, timeout: 12000 }, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        res.resume();
        const next = new URL(res.headers.location, url).toString();
        return resolve(probe(next, redirects + 1));
      }
      res.resume();
      resolve({ url, status: res.statusCode, size: res.headers['content-length'], host: new URL(url).host });
    });
    req.on('error', (e) => resolve({ url, status: 'ERR:' + (e.code || e.message) }));
    req.on('timeout', () => { req.destroy(); resolve({ url, status: 'TIMEOUT' }); });
    req.end();
  });
}

(async () => {
  for (const u of MIRRORS) {
    const r = await probe(u);
    const mb = r.size ? (r.size / 1048576).toFixed(1) + 'MB' : '-';
    console.log(`${String(r.status).padEnd(14)} ${mb.padEnd(10)} ${u.slice(0, 70)}`);
  }
})();
