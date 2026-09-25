#!/usr/bin/env node
// Screenshot helper untuk pilihan terakhir "Flutter Web" — lihat
// ../references/render-method.md bagian 3. Butuh paket `playwright` beserta
// browser Chromium-nya. Kalau terpasang global, arahkan NODE_PATH ke folder
// node_modules global (`npm root -g`) alih-alih `npm install` di repo ini.
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
