const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const adbPath = 'C:\\Users\\chipr\\AppData\\Local\\Android\\Sdk\\platform-tools\\adb.exe';

function capture(outPath) {
  const dir = path.dirname(outPath);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  const buf = execSync(`"${adbPath}" exec-out screencap -p`, { maxBuffer: 50 * 1024 * 1024 });
  fs.writeFileSync(outPath, buf);
  console.log(`Saved ${buf.length} bytes to ${outPath}`);
}

capture('marketing/assets/current_emulator.png');
