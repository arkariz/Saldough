#!/usr/bin/env node
// Screenshot helper untuk metode cadangan "jalankan sebagai Flutter Web" —
// lihat ../references/web-run-method.md. Jalankan dengan
// NODE_PATH=/opt/node22/lib/node_modules supaya `playwright` (terpasang
// global di sandbox ini) ke-resolve tanpa perlu `npm install` lokal.
//
// Usage:
//   node shoot.js --url http://localhost:8080 --out /tmp/shot.png \
//     [--width 390] [--height 844] [--wait 1500] \
//     [--click x,y] [--click x,y ...] [--click-wait 500]
//
// Tiap --click mengklik koordinat itu (piksel CSS, relatif viewport) lalu
// menunggu --click-wait ms sebelum klik berikutnya — dipakai untuk
// berpindah tab bottom-nav Flutter (bukan route go_router, jadi tidak bisa
// lewat URL) sebelum screenshot akhir diambil.

const { chromium } = require('playwright');

function parseArgs(argv) {
  const args = { clicks: [], width: 390, height: 844, wait: 1000, clickWait: 500 };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--url') args.url = argv[++i];
    else if (a === '--out') args.out = argv[++i];
    else if (a === '--width') args.width = Number(argv[++i]);
    else if (a === '--height') args.height = Number(argv[++i]);
    else if (a === '--wait') args.wait = Number(argv[++i]);
    else if (a === '--click-wait') args.clickWait = Number(argv[++i]);
    else if (a === '--click') {
      const [x, y] = argv[++i].split(',').map(Number);
      args.clicks.push({ x, y });
    } else {
      throw new Error(`Argumen tidak dikenal: ${a}`);
    }
  }
  if (!args.url || !args.out) {
    throw new Error('--url dan --out wajib diisi');
  }
  return args;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const browser = await chromium.launch({
    executablePath: '/opt/pw-browsers/chromium',
  });
  try {
    const page = await browser.newPage({
      viewport: { width: args.width, height: args.height },
    });
    await page.goto(args.url);
    await page.waitForTimeout(args.wait);
    for (const { x, y } of args.clicks) {
      await page.mouse.click(x, y);
      await page.waitForTimeout(args.clickWait);
    }
    await page.screenshot({ path: args.out });
    console.log(`Tersimpan: ${args.out}`);
  } finally {
    await browser.close();
  }
}

main().catch((err) => {
  console.error(err.message);
  process.exit(1);
});
