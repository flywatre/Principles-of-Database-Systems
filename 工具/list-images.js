// 列出 Ubuntu WSL rootfs 镜像目录，找出可用的 22.04 (jammy) 文件
const https = require('https');

const UA = { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' };

function fetchText(url) {
  return new Promise((resolve, reject) => {
    const req = https.get(url, { headers: UA, timeout: 30000 }, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        res.resume();
        return resolve(fetchText(res.headers.location));
      }
      let d = '';
      res.setEncoding('utf8');
      res.on('data', (c) => (d += c));
      res.on('end', () => resolve({ status: res.statusCode, body: d }));
    });
    req.on('error', reject);
    req.on('timeout', () => { req.destroy(); reject(new Error('timeout')); });
  });
}

(async () => {
  const url = 'https://cloud-images.ubuntu.com/wsl/jammy/current/';
  const r = await fetchText(url);
  console.log('HTTP', r.status, url);

  // 解析 Apache 目录列表：<a href="x">x</a> ... <td>日期</td> <td>大小</td>
  const re = /href="([^"?/][^"]*)"[^>]*>[^<]*<\/a><\/td><td[^>]*>[^<]*<\/td><td[^>]*>([^<]*)<\/td><td[^>]*>([^<]*)<\/td>/g;
  let m;
  const rows = [];
  while ((m = re.exec(r.body)) !== null) rows.push(m.slice(1));

  if (!rows.length) {
    console.log('--- 未解析到表格，原始 HTML 片段 ---');
    console.log(r.body.slice(0, 2000));
    return;
  }
  for (const [name, date, size] of rows) {
    console.log(name.padEnd(56), date.trim().padEnd(20), size.trim());
  }
})().catch((e) => { console.error('ERR', e.message); process.exit(1); });
