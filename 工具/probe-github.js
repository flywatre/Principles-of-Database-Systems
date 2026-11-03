// 探测 github.com 的发布页是否可达（备选：直接从 releases 页面取 MSIX 包地址）
const https = require('https');

const UA = { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' };

function get(url, redirects = 0) {
  return new Promise((resolve, reject) => {
    if (redirects > 6) return reject(new Error('redirect loop'));
    https.get(url, { headers: UA, timeout: 25000 }, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        res.resume();
        return resolve(get(new URL(res.headers.location, url).toString(), redirects + 1));
      }
      let d = '';
      res.setEncoding('utf8');
      res.on('data', (c) => (d += c));
      res.on('end', () => resolve({ status: res.statusCode, url, body: d }));
    }).on('error', reject).on('timeout', function () { this.destroy(); reject(new Error('timeout')); });
  });
}

(async () => {
  const r = await get('https://github.com/microsoft/WSL/releases/latest');
  console.log('releases/latest ->', r.status, '|', r.url);
  if (r.status === 200) {
    const m = [...r.body.matchAll(/href="([^"]*Microsoft\.WSL[^"]*\.msixbundle)"/g)].map((x) => x[1]);
    console.log('页面内 MSIX 链接:', m.length ? [...new Set(m)].join('\n  ') : '未找到');
    const tag = r.url.match(/\/tag\/(.+)$/);
    if (tag) {
      console.log('最新版本标签:', tag[1]);
      const assetPath = `/microsoft/WSL/releases/expanded_assets/${tag[1]}`;
      const a = await get('https://github.com' + assetPath);
      console.log('assets 列表 ->', a.status);
      if (a.status === 200) {
        const files = [...a.body.matchAll(/href="([^"]*\.(?:msixbundle|msi|txt))"/g)].map((x) => x[1]);
        [...new Set(files)].slice(0, 10).forEach((f) => console.log('  ', f));
      }
    }
  }
})().catch((e) => console.error('ERR', e.code || e.message));
