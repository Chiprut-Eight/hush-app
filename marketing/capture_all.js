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
      let chunks = [];
      res.on('data', chunk => chunks.push(chunk));
      res.on('end', () => {
        if (res.statusCode !== 200) {
          return reject(new Error('Server returned status: ' + res.statusCode));
        }
        resolve(Buffer.concat(chunks));
      });
    });
    req.on('error', reject);
  });
}

async function main() {
  console.log('Forwarding adb port 8888...');
  execFileSync(ADB_PATH, ['-s', 'emulator-5554', 'forward', 'tcp:8888', 'tcp:8888']);

  const languages = ['he', 'en'];

  for (const lang of languages) {
    const langDir = path.join(RAW_DIR, lang);
    if (!fs.existsSync(langDir)) {
      fs.mkdirSync(langDir, { recursive: true });
    }

    console.log(`\n=== Capturing Language: ${lang.toUpperCase()} ===`);
    for (let s = 1; s <= 10; s++) {
      process.stdout.write(`Switching to Screen ${s} [${lang}]... `);
      
      const destFile = path.join(langDir, `screen_${s}.png`);
      
      try {
        const buf = await setScreen(s, lang);
        
        if (buf.length > 1024) {
          fs.writeFileSync(destFile, buf);
          const size = (buf.length / 1024).toFixed(1);
          console.log(`Captured! (${size} KB) -> ${destFile}`);
        } else {
          console.log(`Error! Buffer too small: ${buf.length} bytes`);
        }
      } catch (err) {
        console.log(`Error capturing screen ${s}: ${err.message}`);
      }
      
      await sleep(500); // brief pause between screens
    }
  }

  console.log('\nAll 20 authentic screens successfully generated internally!');
}

main().catch(err => {
  console.error('Capture script error:', err);
});
