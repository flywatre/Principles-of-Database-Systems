// 下载 WSL2 离线安装所需文件到 _wsl_assets/，并校验 SHA256
const https = require('https');
const http = require('http');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const OUT = path.join(__dirname, '..', '_wsl_assets');
const UA = { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' };

function open(url, redirects = 0) {
  return new Promise((resolve, reject) => {
    if (redirects > 6) return reject(new Error('too many redirects'));
    const mod = url.startsWith('http://') ? http : https;
    const req = mod.get(url, { headers: UA, timeout: 60000 }, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        res.resume();
        const next = new URL(res.headers.location, url).toString();
        return resolve(open(next, redirects + 1));
      }
      resolve(res);
    });
    req.on('error', reject);
    req.on('timeout', () => { req.destroy(); reject(new Error('connect timeout')); });
  });
}

async function getText(url) {
  const res = await open(url);
  let d = '';
  res.setEncoding('utf8');
  for await (const c of res) d += c;
  return d;
}

async function download(url, dest) {
  const res = await open(url);
  if (res.statusCode !== 200) throw new Error(`HTTP ${res.statusCode} for ${url}`);
  const total = parseInt(res.headers['content-length'] || '0', 10);
  const tmp = dest + '.part';
  const out = fs.createWriteStream(tmp);
  let got = 0;
  let lastPct = -1;
  const started = Date.now();

  await new Promise((resolve, reject) => {
    res.on('data', (chunk) => {
      got += chunk.length;
      if (total) {
        const pct = Math.floor((got / total) * 100);
        if (pct >= lastPct + 5) {
          lastPct = pct;
          const mb = (got / 1048576).toFixed(1);
          const tm = ((Date.now() - started) / 1000).toFixed(0);
          process.stdout.write(`\r    ${path.basename(dest)}  ${pct}%  ${mb}MB  ${tm}s      `);
        }
      }
    });
    res.on('end', resolve);
    res.on('error', reject);
    out.on('error', reject);
    res.pipe(out);
  });

  await new Promise((r) => out.end(r));
  fs.renameSync(tmp, dest);
  process.stdout.write('\n');
  return dest;
}

function sha256(file) {
  return new Promise((resolve, reject) => {
    const h = crypto.createHash('sha256');
    const s = fs.createReadStream(file);
    s.on('data', (d) => h.update(d));
    s.on('end', () => resolve(h.digest('hex')));
    s.on('error', reject);
  });
}

(async () => {
  fs.mkdirSync(OUT, { recursive: true });
  console.log(`输出目录: ${OUT}\n`);

  const base = 'https://cloud-images.ubuntu.com/wsl/jammy/current/';
  const rootfsName = 'ubuntu-jammy-wsl-amd64-ubuntu22.04lts.rootfs.tar.gz';
  const rootfs = path.join(OUT, rootfsName);

  if (fs.existsSync(rootfs) && fs.statSync(rootfs).size > 300 * 1048576) {
    console.log('rootfs 已存在，跳过下载');
  } else {
    console.log('下载 Ubuntu 22.04 rootfs ...');
    await download(base + rootfsName, rootfs);
  }

  console.log('下载 SHA256SUMS ...');
  const sums = await getText(base + 'SHA256SUMS');
  const line = sums.split('\n').find((l) => l.includes(rootfsName));
  if (line) {
    const expect = line.trim().split(/\s+/)[0];
    process.stdout.write('校验 SHA256 ... ');
    const actual = await sha256(rootfs);
    if (actual === expect) console.log('通过');
    else { console.log(`失败!\n  期望 ${expect}\n  实际 ${actual}`); process.exitCode = 2; }
  } else {
    console.log('SHA256SUMS 里没有该文件，跳过校验');
  }

  const msi = path.join(OUT, 'wsl_update_x64.msi');
  if (fs.existsSync(msi) && fs.statSync(msi).size > 1024 * 1024) {
    console.log('内核 MSI 已存在，跳过下载');
  } else {
    console.log('下载 WSL2 内核 MSI ...');
    await download('https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi', msi);
  }

  // 完整版 WSL 应用（3.0.3）。github.com 网页与 release 资源都可达，
  // 只是 api.github.com 被 403，所以这里直接写死版本号。
  const wslMsi = path.join(OUT, 'wsl.3.0.3.0.x64.msi');
  if (fs.existsSync(wslMsi) && fs.statSync(wslMsi).size > 10 * 1048576) {
    console.log('WSL 应用 MSI 已存在，跳过下载');
  } else {
    console.log('下载 WSL 3.0.3 应用 MSI ...');
    await download('https://github.com/microsoft/WSL/releases/download/3.0.3/wsl.3.0.3.0.x64.msi', wslMsi);
  }

  console.log('\n完成：');
  for (const f of fs.readdirSync(OUT)) {
    console.log('  ' + f.padEnd(52) + (fs.statSync(path.join(OUT, f)).size / 1048576).toFixed(1) + ' MB');
  }
})().catch((e) => { console.error('\nERR', e.message); process.exit(1); });
