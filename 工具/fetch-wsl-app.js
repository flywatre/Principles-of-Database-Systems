// 通过 GitHub 镜像下载 WSL 3.0.3 应用 MSI（objects.githubusercontent.com 被墙）
const https = require('https');
const fs = require('fs');
const path = require('path');

const OUT = path.join(__dirname, '..', '_wsl_assets');
const DEST = path.join(OUT, 'wsl.3.0.3.0.x64.msi');
const TARGET = 'https://github.com/microsoft/WSL/releases/download/3.0.3/wsl.3.0.3.0.x64.msi';

const SOURCES = [
  'https://ghfast.top/' + TARGET,
  'https://gh-proxy.com/' + TARGET,
  'https://ghproxy.net/' + TARGET,
];

const UA = { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' };

function open(url, redirects = 0) {
  return new Promise((resolve, reject) => {
    if (redirects > 6) return reject(new Error('redirect loop'));
    https.get(url, { headers: UA, timeout: 45000 }, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        res.resume();
        return resolve(open(new URL(res.headers.location, url).toString(), redirects + 1));
      }
      resolve(res);
    }).on('error', reject).on('timeout', function () { this.destroy(); reject(new Error('timeout')); });
  });
}

async function tryDownload(url) {
  const res = await open(url);
  if (res.statusCode !== 200) { res.resume(); throw new Error('HTTP ' + res.statusCode); }
  const total = parseInt(res.headers['content-length'] || '0', 10);
  const tmp = DEST + '.part';
  const out = fs.createWriteStream(tmp);
  const started = Date.now();
  let got = 0, lastPct = -1, stalled = false;

  const timer = setTimeout(() => { if (got === 0) { stalled = true; res.destroy(new Error('stalled at 0 bytes')); } }, 30000);

  await new Promise((resolve, reject) => {
    res.on('data', (c) => {
      got += c.length;
      if (total) {
        const pct = Math.floor((got / total) * 100);
        if (pct >= lastPct + 10) {
          lastPct = pct;
          process.stdout.write(`\r    ${pct}%  ${(got / 1048576).toFixed(1)}MB  ${((Date.now() - started) / 1000).toFixed(0)}s      `);
        }
      }
    });
    res.on('end', resolve);
    res.on('error', reject);
    out.on('error', reject);
    res.pipe(out);
  });
  clearTimeout(timer);
  await new Promise((r) => out.end(r));
  if (stalled) throw new Error('stalled');
  if (total && got !== total) throw new Error(`incomplete ${got}/${total}`);
  fs.renameSync(tmp, DEST);
  process.stdout.write('\n');
}

(async () => {
  if (fs.existsSync(DEST) && fs.statSync(DEST).size > 100 * 1048576) {
    console.log('已存在，跳过：', (fs.statSync(DEST).size / 1048576).toFixed(1), 'MB');
    return;
  }
  for (const src of SOURCES) {
    console.log('尝试源:', new URL(src).host);
    try { await tryDownload(src); console.log('成功:', (fs.statSync(DEST).size / 1048576).toFixed(1), 'MB'); return; }
    catch (e) { console.log('  失败:', e.message); try { fs.unlinkSync(DEST + '.part'); } catch {} }
  }
  console.error('所有镜像均失败');
  process.exit(1);
})();
