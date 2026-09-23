const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

const CHROME_PATH = "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe";
const BASE_DIR = __dirname;
const RENDER_HTML_PATH = path.join(BASE_DIR, 'render_engine.html');

const SCREENS = [
  { num: 1, name: '01_welcome' },
  { num: 2, name: '02_nearby_feed' },
  { num: 3, name: '03_interactive_map' },
  { num: 4, name: '04_audio_player' },
  { num: 5, name: '05_record_plant' },
  { num: 6, name: '06_group_hushhh' },
  { num: 7, name: '07_clout_tiers' },
  { num: 8, name: '08_following_feed' },
  { num: 9, name: '09_smart_notifications' },
  { num: 10, name: '10_saved_vault' }
];

const CONFIGS = [
  // Hebrew
  { lang: 'he', device: 'iphone', folder: path.join(BASE_DIR, 'store_screenshots', 'he', 'ios'), suffix: 'iphone' },
  { lang: 'he', device: 'samsung', folder: path.join(BASE_DIR, 'store_screenshots', 'he', 'android'), suffix: 'samsung' },
  // English
  { lang: 'en', device: 'iphone', folder: path.join(BASE_DIR, 'store_screenshots', 'en', 'ios'), suffix: 'iphone' },
  { lang: 'en', device: 'samsung', folder: path.join(BASE_DIR, 'store_screenshots', 'en', 'android'), suffix: 'samsung' }
];

// Ensure all target folders exist
CONFIGS.forEach(cfg => {
  if (!fs.existsSync(cfg.folder)) {
    fs.mkdirSync(cfg.folder, { recursive: true });
  }
});

// Build the queue of jobs
const tasks = [];
for (const cfg of CONFIGS) {
  for (const scr of SCREENS) {
    const outFile = path.join(cfg.folder, `${scr.name}_${cfg.suffix}.png`);
    const fileUrl = `file:///${RENDER_HTML_PATH.replace(/\\/g, '/')}?screen=${scr.num}&device=${cfg.device}&lang=${cfg.lang}`;
    tasks.push({
      id: `${cfg.lang}-${cfg.device}-${scr.name}`,
      outFile,
      fileUrl
    });
  }
}

console.log(`Total screenshots to generate: ${tasks.length}`);

// Concurrency pool runner
const CONCURRENCY = 4;
let activeCount = 0;
let completedCount = 0;
let taskIndex = 0;

function runNext() {
  if (taskIndex >= tasks.length && activeCount === 0) {
    console.log(`\n🎉 All ${completedCount} store screenshots successfully rendered at 1284x2778px!`);
    return;
  }

  while (activeCount < CONCURRENCY && taskIndex < tasks.length) {
    const task = tasks[taskIndex++];
    activeCount++;

    const args = [
      '--headless=new',
      '--disable-gpu',
      '--no-sandbox',
      '--allow-file-access-from-files',
      '--force-device-scale-factor=1',
      '--window-size=1284,2778',
      '--virtual-time-budget=2000',
      '--run-all-compositor-stages-before-draw',
      '--hide-scrollbars',
      `--screenshot=${task.outFile}`,
      task.fileUrl
    ];

    const proc = spawn(CHROME_PATH, args);

    proc.on('close', (code) => {
      activeCount--;
      completedCount++;
      const percent = Math.round((completedCount / tasks.length) * 100);
      console.log(`[${completedCount}/${tasks.length}] (${percent}%) Rendered: ${path.basename(task.outFile)} [${task.id}]`);
      runNext();
    });

    proc.on('error', (err) => {
      console.error(`Error rendering task ${task.id}:`, err);
      activeCount--;
      runNext();
    });
  }
}

// Start rendering
runNext();
