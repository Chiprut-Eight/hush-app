const { execFileSync } = require('child_process');
const http = require('http');
const fs = require('fs');
const path = require('path');

const ADB_PATH = path.join(process.env.LOCALAPPDATA, 'Android', 'Sdk', 'platform-tools', 'adb.exe');
const BASE_DIR = __dirname;
const RAW_DIR = path.join(BASE_DIR, 'raw_captures');

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

function setScreen(screen, lang) {
  return new Promise((resolve, reject) => {
    const req = http.get(`http://127.0.0.1:8888/set?screen=${screen}&lang=${lang}`, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve(data.trim()));
    });
    req.on('error', reject);
  });
}

function captureScreenshot(destPath) {
  const buf = execFileSync(ADB_PATH, ['exec-out', 'screencap', '-p'], { maxBuffer: 25 * 1024 * 1024 });
  fs.writeFileSync(destPath, buf);
}

async function main() {
  console.log('Forwarding adb port 8888...');
  execFileSync(ADB_PATH, ['forward', 'tcp:8888', 'tcp:8888']);

  const languages = ['he', 'en'];

  for (const lang of languages) {
    const langDir = path.join(RAW_DIR, lang);
    if (!fs.existsSync(langDir)) {
      fs.mkdirSync(langDir, { recursive: true });
    }

    console.log(`\n=== Capturing Language: ${lang.toUpperCase()} ===`);
    for (let s = 1; s <= 10; s++) {
      process.stdout.write(`Switching to Screen ${s} [${lang}]... `);
      await setScreen(s, lang);
      // Wait for UI render and map/animation stabilization (extra time for map tiles)
      await sleep(s === 3 ? 3500 : 1400);

      const destFile = path.join(langDir, `screen_${s}.png`);
      captureScreenshot(destFile);
      const size = (fs.statSync(destFile).size / 1024).toFixed(1);
      console.log(`Captured! (${size} KB) -> ${destFile}`);
    }
  }

  console.log('\nAll 20 authentic screens successfully captured from emulator!');
}

main().catch(err => {
  console.error('Fatal capture error:', err);
  process.exit(1);
});
