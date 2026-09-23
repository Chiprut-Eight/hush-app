const fs = require('fs');
const path = require('path');

const engineContent = `<!DOCTYPE html>
<html lang="he" dir="rtl">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=1284, height=2778, initial-scale=1.0">
  <title>Hushhh Store Screenshot Renderer - Authentic Flutter Edition</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Assistant:wght@400;500;600;700;800;900&family=Plus+Jakarta+Sans:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">
  <style>
    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
      -webkit-font-smoothing: antialiased;
    }

    :root {
      --bg-primary: #0A0E17;
      --bg-secondary: #111827;
      --bg-card: rgba(20, 27, 45, 0.85);
      --bg-card-glass: rgba(30, 38, 56, 0.65);
      --border-subtle: rgba(255, 255, 255, 0.08);
      --border-accent: rgba(103, 232, 249, 0.35);
      --text-primary: #F1F5F9;
      --text-secondary: #94A3B8;
      --text-muted: #64748B;
      --cyan: #67E8F9;
      --blue: #4A9EFF;
      --purple: #A855F7;
      --pink: #EC4899;
      --orange: #F97316;
      --yellow: #FBBF24;
      --green: #34D399;
      --tier-red: #EF4444;
    }

    body {
      width: 1284px;
      height: 2778px;
      background: #0A0E17;
      color: var(--text-primary);
      font-family: 'Assistant', -apple-system, BlinkMacSystemFont, sans-serif;
      overflow: hidden;
      position: relative;
    }

    body.lang-en {
      font-family: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, sans-serif;
      direction: ltr;
    }

    /* Ambient Background Glow */
    .ambient-canvas {
      position: absolute;
      top: 0;
      left: 0;
      width: 1284px;
      height: 2778px;
      z-index: 0;
      pointer-events: none;
      overflow: hidden;
    }

    .ambient-glow-top {
      position: absolute;
      top: -180px;
      left: 50%;
      transform: translateX(-50%);
      width: 1100px;
      height: 850px;
      background: radial-gradient(circle, rgba(103, 232, 249, 0.22) 0%, rgba(74, 158, 255, 0.14) 40%, transparent 70%);
      filter: blur(70px);
    }

    .ambient-glow-bottom {
      position: absolute;
      bottom: -150px;
      right: -100px;
      width: 950px;
      height: 950px;
      background: radial-gradient(circle, rgba(168, 85, 247, 0.2) 0%, rgba(236, 72, 153, 0.1) 50%, transparent 70%);
      filter: blur(80px);
    }

    .ambient-ripple {
      position: absolute;
      border-radius: 50%;
      border: 1.5px solid rgba(103, 232, 249, 0.08);
      top: 260px;
      left: 50%;
      transform: translateX(-50%);
      pointer-events: none;
    }
    .ripple-1 { width: 640px; height: 640px; }
    .ripple-2 { width: 960px; height: 960px; border-color: rgba(74, 158, 255, 0.06); }
    .ripple-3 { width: 1280px; height: 1280px; border-color: rgba(168, 85, 247, 0.05); }

    /* Marketing Header Area */
    .marketing-header {
      position: relative;
      z-index: 10;
      width: 100%;
      height: 480px;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 60px 70px 20px;
      text-align: center;
    }

    .badge-pill {
      display: inline-flex;
      align-items: center;
      gap: 12px;
      padding: 12px 28px;
      border-radius: 50px;
      background: rgba(255, 255, 255, 0.05);
      border: 1px solid rgba(103, 232, 249, 0.35);
      box-shadow: 0 0 30px rgba(103, 232, 249, 0.2);
      margin-bottom: 24px;
    }

    .badge-dot {
      width: 12px;
      height: 12px;
      border-radius: 50%;
      background: var(--cyan);
      box-shadow: 0 0 12px var(--cyan);
    }

    .badge-text {
      font-size: 26px;
      font-weight: 800;
      letter-spacing: 0.5px;
      color: #F1F5F9;
    }

    .marketing-title {
      font-size: 80px;
      font-weight: 900;
      line-height: 1.15;
      margin-bottom: 18px;
      max-width: 1140px;
      background: linear-gradient(135deg, #FFFFFF 10%, #E2E8F0 50%, var(--cyan) 100%);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      text-shadow: 0 10px 40px rgba(0, 0, 0, 0.6);
    }

    .marketing-subtitle {
      font-size: 36px;
      font-weight: 600;
      line-height: 1.35;
      color: #94A3B8;
      max-width: 1040px;
    }

    /* Device Container */
    .device-stage {
      position: relative;
      z-index: 10;
      width: 100%;
      height: 2298px;
      display: flex;
      justify-content: center;
      align-items: flex-start;
    }

    /* IPHONE 16 PRO FRAME */
    .device-frame-iphone {
      width: 1010px;
      height: 2150px;
      background: #0A0E17;
      border-radius: 76px;
      box-shadow: 
        0 0 0 3px #374151,
        0 0 0 12px #1e2530,
        0 0 0 16px #080a0f,
        0 40px 100px -20px rgba(0, 0, 0, 0.95),
        0 0 80px rgba(103, 232, 249, 0.22);
      position: relative;
      overflow: hidden;
      display: flex;
      flex-direction: column;
    }

    .iphone-island-container {
      position: absolute;
      top: 18px;
      left: 50%;
      transform: translateX(-50%);
      width: 290px;
      height: 52px;
      background: #000000;
      border-radius: 30px;
      z-index: 50;
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 0 18px;
      box-shadow: 0 4px 14px rgba(0,0,0,0.6);
    }

    .island-camera {
      width: 18px;
      height: 18px;
      border-radius: 50%;
      background: #090d16;
      border: 1px solid #1e293b;
      box-shadow: inset 0 0 4px #00e5ff44;
    }

    .island-sensor {
      width: 12px;
      height: 12px;
      border-radius: 50%;
      background: #060910;
    }

    .ios-status-bar {
      height: 84px;
      padding: 0 48px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      color: #FFFFFF;
      font-size: 24px;
      font-weight: 700;
      z-index: 40;
      position: relative;
      direction: ltr !important;
    }

    .ios-status-time {
      font-family: 'Plus Jakarta Sans', sans-serif;
      font-weight: 800;
      font-size: 26px;
    }

    .ios-status-icons {
      display: flex;
      align-items: center;
      gap: 12px;
    }

    .ios-home-bar {
      position: absolute;
      bottom: 16px;
      left: 50%;
      transform: translateX(-50%);
      width: 260px;
      height: 7px;
      background: rgba(255, 255, 255, 0.75);
      border-radius: 10px;
      z-index: 50;
    }

    /* SAMSUNG GALAXY S24 ULTRA FRAME */
    .device-frame-samsung {
      width: 1010px;
      height: 2150px;
      background: #0A0E17;
      border-radius: 40px;
      box-shadow: 
        0 0 0 3px #475569,
        0 0 0 10px #1e293b,
        0 0 0 14px #070a10,
        0 40px 100px -20px rgba(0, 0, 0, 0.95),
        0 0 80px rgba(168, 85, 247, 0.25);
      position: relative;
      overflow: hidden;
      display: flex;
      flex-direction: column;
    }

    .samsung-punch-hole {
      position: absolute;
      top: 24px;
      left: 50%;
      transform: translateX(-50%);
      width: 24px;
      height: 24px;
      background: #000000;
      border-radius: 50%;
      z-index: 50;
      border: 1.5px solid #1e293b;
    }

    .samsung-status-bar {
      height: 76px;
      padding: 0 42px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      color: #FFFFFF;
      font-size: 22px;
      font-weight: 600;
      z-index: 40;
      position: relative;
      direction: ltr !important;
    }

    .samsung-status-time {
      font-family: 'Plus Jakarta Sans', sans-serif;
      font-weight: 800;
      font-size: 25px;
    }

    .samsung-status-icons {
      display: flex;
      align-items: center;
      gap: 14px;
    }

    .samsung-nav-bar {
      position: absolute;
      bottom: 14px;
      left: 50%;
      transform: translateX(-50%);
      width: 200px;
      height: 6px;
      background: rgba(255, 255, 255, 0.55);
      border-radius: 10px;
      z-index: 50;
    }

    /* FLUTTER APP VIEWPORT */
    .app-screen-viewport {
      flex: 1;
      display: flex;
      flex-direction: column;
      position: relative;
      background: #0A0E17;
      overflow: hidden;
    }

    /* AUTHENTIC TOP BANNER (From lib/main.dart lines 102-167) */
    .flutter-top-header {
      padding: 12px 32px 6px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      direction: ltr !important; /* Always physical left */
      z-index: 35;
    }

    .flutter-top-banner-img {
      height: 38px;
      object-fit: contain;
    }

    .flutter-back-pill {
      background: rgba(20, 27, 45, 0.85);
      border: 1px solid rgba(255, 255, 255, 0.12);
      border-radius: 18px;
      padding: 6px 14px;
      display: flex;
      align-items: center;
      gap: 6px;
      color: #94A3B8;
      font-size: 15px;
      font-weight: 700;
    }

    /* AUTHENTIC APP BAR */
    .flutter-app-bar {
      padding: 6px 32px 14px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      z-index: 35;
    }

    .flutter-app-bar-left {
      display: flex;
      align-items: center;
      gap: 16px;
    }

    .flutter-menu-btn {
      font-size: 26px;
      color: #FFFFFF;
    }

    .flutter-app-bar-title {
      font-size: 30px;
      font-weight: 900;
      color: #FFFFFF;
      letter-spacing: -0.5px;
    }

    .flutter-app-bar-actions {
      display: flex;
      align-items: center;
      gap: 20px;
    }

    .flutter-action-icon {
      font-size: 24px;
      color: #FFFFFF;
      position: relative;
    }

    .unread-dot {
      position: absolute;
      top: -2px;
      right: -2px;
      width: 10px;
      height: 10px;
      border-radius: 50%;
      background: var(--cyan);
      box-shadow: 0 0 8px var(--cyan);
    }

    /* AUTHENTIC BOTTOM NAV BAR (From lib/screens/app_shell.dart lines 240-290) */
    .flutter-bottom-nav {
      height: 124px;
      background: #0A0E17;
      border-top: 1px solid rgba(255, 255, 255, 0.08);
      display: flex;
      align-items: center;
      justify-content: space-around;
      padding: 0 16px;
      z-index: 40;
    }

    .flutter-nav-tab {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 5px;
      color: #94A3B8;
      font-size: 16px;
      font-weight: 700;
    }

    .flutter-nav-tab.active {
      color: var(--cyan);
    }

    .flutter-nav-center-btn {
      width: 72px;
      height: 72px;
      border-radius: 50%;
      background: linear-gradient(135deg, var(--cyan), var(--blue), var(--purple), var(--pink));
      display: flex;
      align-items: center;
      justify-content: center;
      box-shadow: 0 4px 20px rgba(239, 68, 68, 0.45);
      margin-top: -26px;
    }

    /* SCREEN CONTENT CONTAINER */
    .flutter-screen-content {
      flex: 1;
      overflow: hidden;
      position: relative;
      display: flex;
      flex-direction: column;
      padding: 16px 28px;
      gap: 20px;
    }

    /* AUTHENTIC FLUTTER SECRET CARD (From lib/widgets/secret_card.dart) */
    .flutter-secret-card {
      background: rgba(30, 38, 56, 0.65);
      border: 1px solid rgba(255, 255, 255, 0.1);
      border-radius: 24px;
      padding: 22px 24px;
      position: relative;
      box-shadow: 0 0 24px -2px var(--tier-glow, rgba(103, 232, 249, 0.35)), 0 16px 36px rgba(0,0,0,0.5);
      backdrop-filter: blur(14px);
      display: flex;
      flex-direction: column;
      gap: 16px;
    }

    .card-top-row {
      display: flex;
      align-items: center;
      justify-content: space-between;
    }

    .creator-info {
      display: flex;
      align-items: center;
      gap: 14px;
    }

    .creator-avatar-ring {
      width: 52px;
      height: 52px;
      border-radius: 50%;
      background: var(--tier-color, var(--cyan));
      padding: 2.5px;
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .creator-avatar-inner {
      width: 100%;
      height: 100%;
      border-radius: 50%;
      background: #0A0E17;
      display: flex;
      align-items: center;
      justify-content: center;
      color: #FFFFFF;
      font-weight: 800;
      font-size: 20px;
    }

    .creator-names {
      display: flex;
      flex-direction: column;
      gap: 2px;
    }

    .creator-name-row {
      display: flex;
      align-items: center;
      gap: 8px;
    }

    .creator-username {
      font-size: 20px;
      font-weight: 800;
      color: #FFFFFF;
    }

    .time-ago {
      font-size: 14px;
      color: var(--text-muted);
    }

    .secret-type-badge {
      font-size: 14px;
      font-weight: 700;
      color: var(--tier-color, var(--cyan));
    }

    .distance-pill {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 6px 16px;
      border-radius: 20px;
      background: rgba(103, 232, 249, 0.12);
      border: 1px solid rgba(103, 232, 249, 0.4);
      color: var(--cyan);
      font-size: 15px;
      font-weight: 800;
    }

    .audio-player-box {
      background: rgba(0, 0, 0, 0.35);
      border-radius: 18px;
      padding: 14px 20px;
      display: flex;
      align-items: center;
      gap: 18px;
    }

    .play-btn-circle {
      width: 52px;
      height: 52px;
      border-radius: 50%;
      background: var(--cyan);
      display: flex;
      align-items: center;
      justify-content: center;
      box-shadow: 0 0 20px rgba(103, 232, 249, 0.45);
    }

    .audio-waveform-bars {
      display: flex;
      align-items: center;
      gap: 4px;
      flex: 1;
      height: 52px;
    }

    .wf-bar {
      flex: 1;
      background: linear-gradient(180deg, var(--cyan), var(--purple));
      border-radius: 3px;
      min-height: 8px;
    }

    .card-footer-actions {
      display: flex;
      align-items: center;
      justify-content: space-between;
      border-top: 1px solid rgba(255, 255, 255, 0.08);
      padding-top: 14px;
      color: var(--text-secondary);
      font-size: 16px;
      font-weight: 700;
    }

    .action-badge {
      display: flex;
      align-items: center;
      gap: 6px;
    }

    /* SEGMENTED CONTROL */
    .flutter-segmented-control {
      display: flex;
      background: rgba(20, 27, 45, 0.85);
      border: 1px solid rgba(255, 255, 255, 0.08);
      border-radius: 16px;
      padding: 4px;
      margin-bottom: 8px;
    }

    .seg-tab {
      flex: 1;
      text-align: center;
      padding: 14px;
      border-radius: 12px;
      font-size: 18px;
      font-weight: 800;
      color: #94A3B8;
      transition: all 0.2s ease;
    }

    .seg-tab.active {
      background: #1E2638;
      color: #FFFFFF;
      box-shadow: 0 4px 14px rgba(0,0,0,0.4);
    }

    /* PRIMARY CYAN BUTTON */
    .flutter-primary-btn {
      width: 100%;
      height: 68px;
      border-radius: 18px;
      background: var(--cyan);
      border: none;
      color: #0A0E17;
      font-size: 22px;
      font-weight: 900;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 12px;
      box-shadow: 0 0 25px rgba(103, 232, 249, 0.4);
    }

    /* EQUALIZER WAVE (7 bars matching lib/screens/login_screen.dart) */
    .soundwave-container {
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 7px;
      height: 48px;
      margin-top: 24px;
    }

    .wave-line {
      width: 4px;
      border-radius: 3px;
      background: linear-gradient(180deg, var(--cyan), var(--purple));
    }
  </style>
</head>
<body>

  <!-- Ambient Glow & Rings -->
  <div class="ambient-canvas">
    <div class="ambient-glow-top"></div>
    <div class="ambient-glow-bottom"></div>
    <div class="ambient-ripple ripple-1"></div>
    <div class="ambient-ripple ripple-2"></div>
    <div class="ambient-ripple ripple-3"></div>
  </div>

  <!-- Marketing Header -->
  <div class="marketing-header">
    <div class="badge-pill">
      <div class="badge-dot"></div>
      <span class="badge-text" id="header-badge">Hushhh • Official</span>
    </div>
    <h1 class="marketing-title" id="header-title">Title Here</h1>
    <p class="marketing-subtitle" id="header-subtitle">Subtitle description goes here</p>
  </div>

  <!-- Device Stage -->
  <div class="device-stage" id="device-stage">
    <!-- Populated by JavaScript -->
  </div>

  <script>
    const urlParams = new URLSearchParams(window.location.search);
    const screenNum = parseInt(urlParams.get('screen')) || 1;
    const device = urlParams.get('device') || 'iphone';
    const lang = urlParams.get('lang') || 'he';

    const SCREENS_CONFIG = {
      1: {
        id: 'welcome',
        isFullScreen: true,
        he: { badge: 'הרשת החברתית הגיאו-אקוסטית', title: 'ברוכים הבאים ל-Hushhh', subtitle: 'הרשת החברתית הגיאו-אקוסטית הראשונה' },
        en: { badge: 'Geo-Acoustic Social Network', title: 'Welcome to Hushhh', subtitle: 'The First Geo-Acoustic Social Network' }
      },
      2: {
        id: 'nearby_feed',
        activeTab: 0,
        he: { badge: 'רדאר סודות מקומי', title: 'Hushhh בקרבתך', subtitle: 'גלה Hushhh אקוסטיים סביבך בזמן אמת' },
        en: { badge: 'Local Acoustic Radar', title: 'Nearby Hushhh', subtitle: 'Discover acoustic Hushhh around you in real time' }
      },
      3: {
        id: 'interactive_map',
        activeTab: 1,
        he: { badge: 'ניווט אקוסטי במרחב', title: 'מפת Hushhh אינטראקטיבית', subtitle: 'חקור את הסביבה ומצא Hushhh מעניינים על המפה' },
        en: { badge: 'Spatial Acoustic Navigation', title: 'Interactive Hushhh Map', subtitle: 'Explore your surroundings & find intriguing Hushhh on the map' }
      },
      4: {
        id: 'audio_player',
        activeTab: 0,
        he: { badge: 'איכות שמע חיה', title: 'האזנה ל-Hushhh', subtitle: 'האזנה בזמן אמת ל-Hushhh, תגובות ועוד' },
        en: { badge: 'Crystal Live Audio', title: 'Listen to Hushhh', subtitle: 'Real-time acoustic audio, reactions & more' }
      },
      5: {
        id: 'record_plant',
        activeTab: 2,
        he: { badge: 'יצירה והטמנה', title: 'הטמן Hushhh', subtitle: 'הקלט Hushhh והטמן במיקום מדויק במרחב' },
        en: { badge: 'Create & Plant', title: 'Plant a Hushhh', subtitle: 'Record a Hushhh & drop it at an exact spatial coordinate' }
      },
      6: {
        id: 'group_hushhh',
        activeTab: 0,
        he: { badge: 'חוויה משותפת', title: 'Hushhh קבוצתי', subtitle: 'Hushhh קבוצתיים שנחשפים רק כשכמה אנשים נפגשים במקום' },
        en: { badge: 'Collaborative Experience', title: 'Group Hushhh', subtitle: 'Group Hushhh unlocked only when multiple people gather together' }
      },
      7: {
        id: 'clout_tiers',
        activeTab: 4,
        he: { badge: 'מוניטין והשפעה', title: 'דרגות והשפעה', subtitle: 'צבור השפעה, עלה בדרגות ופתח יכולות בלעדיות כיוצר תוכן מסקרן' },
        en: { badge: 'Clout & Influence', title: 'Clout & Tiers', subtitle: 'Gain influence, level up and unlock exclusive creator perks' }
      },
      8: {
        id: 'following_feed',
        activeTab: 3,
        he: { badge: 'קהילה יוצרת', title: 'היוצרים שאתה אוהב', subtitle: 'הישאר מחובר ל-Hushhh וליוצרים המרתקים ביותר' },
        en: { badge: 'Creative Community', title: 'Following Feed', subtitle: 'Stay connected to your favorite creators & their Hushhh' }
      },
      9: {
        id: 'smart_notifications',
        activeTab: 4,
        he: { badge: 'התראות חכמות', title: 'התראות חכמות בזמן אמת', subtitle: 'בחר מתי להתעדכן - פתיחת Hushhh קבוצתיים, עוקבים ותגובות' },
        en: { badge: 'Smart Alerts', title: 'Smart Notifications', subtitle: 'Stay tuned on group unlocks, new followers and reactions' }
      },
      10: {
        id: 'saved_vault',
        activeTab: 4,
        he: { badge: 'כספת אישית', title: 'Hushhh שמורים', subtitle: 'קבל התראה כשאתה חולף ליד Hushhh ושמור מועדפים' },
        en: { badge: 'Personal Vault', title: 'Saved Hushhh', subtitle: 'Get notified as you pass by a Hushhh & save favorites' }
      }
    };

    if (lang === 'en') {
      document.body.classList.add('lang-en');
      document.documentElement.lang = 'en';
      document.documentElement.dir = 'ltr';
    } else {
      document.body.classList.remove('lang-en');
      document.documentElement.lang = 'he';
      document.documentElement.dir = 'rtl';
    }

    const screenData = SCREENS_CONFIG[screenNum] || SCREENS_CONFIG[1];
    const text = lang === 'en' ? screenData.en : screenData.he;

    document.getElementById('header-badge').textContent = text.badge;
    document.getElementById('header-title').textContent = text.title;
    document.getElementById('header-subtitle').textContent = text.subtitle;

    function generateWaveformHtml(count, minH = 12, maxH = 65) {
      let bars = '';
      const heights = [16, 26, 42, 60, 46, 32, 52, 68, 58, 38, 22, 40, 54, 64, 48, 28, 44, 58, 50, 34, 20, 36, 52, 66, 42, 24, 16, 34, 56, 46, 28, 20];
      for (let i = 0; i < count; i++) {
        const h = heights[i % heights.length];
        bars += \`<div class="wf-bar" style="height: \${h}px;"></div>\`;
      }
      return bars;
    }

    // AUTHENTIC FLUTTER SCREENS IMPLEMENTATION
    function getScreenBodyContent(screenId, lang) {
      const isHe = lang === 'he';

      switch(screenId) {
        // SCREEN 1: AUTHENTIC LOGIN SCREEN (From lib/screens/login_screen.dart)
        case 'welcome':
          return \`
            <div style="flex: 1; display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 40px 32px; text-align: center; position: relative;">
              
              <!-- Language Icon on Top Corner -->
              <div style="position: absolute; top: 16px; \${isHe ? 'left: 16px;' : 'right: 16px;'} display: flex; align-items: center; gap: 8px; color: #FFFFFF; font-size: 16px; font-weight: 700; background: rgba(255,255,255,0.06); padding: 8px 16px; border-radius: 20px; border: 1px solid rgba(255,255,255,0.12);">
                <span>🌐</span>
                <span>\${isHe ? 'עברית' : 'English'}</span>
              </div>

              <!-- Pulsing Logo with Cyan Ambient Glow -->
              <div style="width: 170px; height: 170px; border-radius: 50%; box-shadow: 0 0 60px rgba(103, 232, 249, 0.45); margin-bottom: 32px; overflow: hidden; border: 3px solid rgba(103, 232, 249, 0.4);">
                <img src="assets/logo_hushhh2.jpeg" style="width: 100%; height: 100%; object-fit: cover;" alt="Hushhh">
              </div>

              <!-- Title & Subtitle Matching App -->
              <div style="font-size: 48px; font-weight: 900; background: linear-gradient(135deg, #67E8F9, #4A9EFF, #A855F7, #EC4899, #F97316, #FBBF24); -webkit-background-clip: text; -webkit-text-fill-color: transparent; margin-bottom: 12px; letter-spacing: -0.5px;">
                Hushhh
              </div>
              <div style="font-size: 22px; color: #94A3B8; max-width: 540px; margin-bottom: 48px; line-height: 1.4;">
                \${isHe ? 'הרשת החברתית הגיאו-אקוסטית הראשונה' : 'The First Geo-Acoustic Social Network'}
              </div>

              <!-- Real Google & Apple Buttons -->
              <div style="width: 100%; display: flex; flex-direction: column; gap: 16px; max-width: 580px;">
                <!-- Google Sign-In -->
                <div style="background: #FFFFFF; color: #1F2937; height: 68px; border-radius: 16px; display: flex; align-items: center; justify-content: center; font-size: 21px; font-weight: 700; gap: 16px; box-shadow: 0 10px 30px rgba(0,0,0,0.4);">
                  <svg width="28" height="28" viewBox="0 0 24 24"><path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/><path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/><path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22.81-.63z"/><path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.52 6.16-4.52z"/></svg>
                  \${isHe ? 'התחברות עם Google' : 'Sign in with Google'}
                </div>

                <!-- Apple Sign-In -->
                <div style="background: #FFFFFF; color: #000000; height: 68px; border-radius: 16px; display: flex; align-items: center; justify-content: center; font-size: 21px; font-weight: 700; gap: 16px; box-shadow: 0 10px 30px rgba(0,0,0,0.4);">
                  <svg width="28" height="28" viewBox="0 0 24 24" fill="black"><path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M15.97 6.37c.61-.74 1.04-1.79.92-2.87-.96.04-2.13.64-2.77 1.39-.58.67-.99 1.74-.86 2.8.01 0 .08.01.12.01.95 0 1.98-.59 2.59-1.33z"/></svg>
                  \${isHe ? 'התחברות עם Apple' : 'Sign in with Apple'}
                </div>
              </div>

              <!-- Authentic Equalizer Wave Lines (7 bars) -->
              <div class="soundwave-container">
                <div class="wave-line" style="height: 14px;"></div>
                <div class="wave-line" style="height: 24px;"></div>
                <div class="wave-line" style="height: 36px;"></div>
                <div class="wave-line" style="height: 48px;"></div>
                <div class="wave-line" style="height: 36px;"></div>
                <div class="wave-line" style="height: 24px;"></div>
                <div class="wave-line" style="height: 14px;"></div>
              </div>
            </div>
          \`;

        // SCREEN 2: AUTHENTIC FEED SCREEN (From lib/screens/feed_screen.dart & widgets/secret_card.dart)
        case 'nearby_feed':
          return \`
            <div style="flex: 1; display: flex; flex-direction: column; gap: 18px;">
              <!-- Card 1: Voice Secret (Cyan Tier 1) -->
              <div class="flutter-secret-card" style="--tier-color: #00F0FF; --tier-glow: rgba(0, 240, 255, 0.35);">
                <div class="card-top-row">
                  <div class="creator-info">
                    <div class="creator-avatar-ring">
                      <div class="creator-avatar-inner">D</div>
                    </div>
                    <div class="creator-names">
                      <div class="creator-name-row">
                        <span class="creator-username">@DanLevi</span>
                        <span class="time-ago">\${isHe ? 'לפני שעה' : '1h ago'}</span>
                      </div>
                      <span class="secret-type-badge">\${isHe ? 'סוד קולי' : 'Voice Hushhh'}</span>
                    </div>
                  </div>
                  <span class="distance-pill">📍 \${isHe ? '45 מטר' : '45m away'}</span>
                </div>

                <div class="audio-player-box">
                  <div class="play-btn-circle">
                    <svg width="22" height="22" viewBox="0 0 24 24" fill="#0A0E17"><polygon points="5 3 19 12 5 21 5 3"/></svg>
                  </div>
                  <div class="audio-waveform-bars">
                    \${generateWaveformHtml(20)}
                  </div>
                  <span style="font-size: 18px; font-weight: 800; color: #E2E8F0;">0:34 / 1:12</span>
                </div>

                <div class="card-footer-actions">
                  <div class="action-badge"><span style="color: #EC4899;">❤️</span> 42</div>
                  <div class="action-badge">💬 8</div>
                  <div class="action-badge">🔖 \${isHe ? 'שמור' : 'Save'}</div>
                </div>
              </div>

              <!-- Card 2: Text Secret (Gold Tier 3) -->
              <div class="flutter-secret-card" style="--tier-color: #FFD700; --tier-glow: rgba(255, 215, 0, 0.25);">
                <div class="card-top-row">
                  <div class="creator-info">
                    <div class="creator-avatar-ring">
                      <div class="creator-avatar-inner">M</div>
                    </div>
                    <div class="creator-names">
                      <div class="creator-name-row">
                        <span class="creator-username">@MayaCohen</span>
                        <span class="time-ago">\${isHe ? 'לפני שעתיים' : '2h ago'}</span>
                      </div>
                      <span class="secret-type-badge">\${isHe ? 'סוד טקסט' : 'Text Hushhh'}</span>
                    </div>
                  </div>
                  <span class="distance-pill">📍 \${isHe ? '110 מטר' : '110m away'}</span>
                </div>

                <div style="font-size: 20px; font-weight: 600; color: #F1F5F9; line-height: 1.45; padding: 4px 0;">
                  \${isHe ? 'גיליתי היום בית קפה מדהים שמוחבא בסמטה הזאת. האקוסטיקה פה משגעת! ☕✨' : 'Just discovered an amazing hidden coffee shop in this alley. The acoustic vibe here is magical! ☕✨'}
                </div>

                <div class="card-footer-actions">
                  <div class="action-badge"><span style="color: #EC4899;">❤️</span> 125</div>
                  <div class="action-badge">💬 14</div>
                  <div class="action-badge">🔖 \${isHe ? 'שמור' : 'Save'}</div>
                </div>
              </div>

              <!-- Card 3: Group Secret (Pink/Purple Tier 5) -->
              <div class="flutter-secret-card" style="--tier-color: #EC4899; --tier-glow: rgba(236, 72, 153, 0.35);">
                <div class="card-top-row">
                  <div class="creator-info">
                    <div class="creator-avatar-ring">
                      <div class="creator-avatar-inner">👥</div>
                    </div>
                    <div class="creator-names">
                      <div class="creator-name-row">
                        <span class="creator-username">\${isHe ? 'סוד קבוצתי' : 'Group Secret'}</span>
                        <span class="time-ago">\${isHe ? 'לפני 3 שעות' : '3h ago'}</span>
                      </div>
                      <span class="secret-type-badge" style="color: #EC4899;">\${isHe ? 'נדרשים 3 משתתפים (2 כבר כאן!)' : '3 people required (2 already here!)'}</span>
                    </div>
                  </div>
                  <span class="distance-pill">📍 \${isHe ? '180 מטר' : '180m away'}</span>
                </div>

                <div style="font-size: 19px; color: #CBD5E1; line-height: 1.4;">
                  \${isHe ? 'סוד קבוצתי מיוחד! הגיעו למיקום זה כדי לחשוף את ההקלטה המשותפת.' : 'Special group secret! Gather at this location to reveal the collaborative recording.'}
                </div>

                <div class="card-footer-actions">
                  <div class="action-badge"><span style="color: #EC4899;">❤️</span> 89</div>
                  <div class="action-badge">💬 6</div>
                  <div class="action-badge">🔓 \${isHe ? 'הצטרף' : 'Join'}</div>
                </div>
              </div>
            </div>
          \`;

        // SCREEN 3: AUTHENTIC MAP SCREEN (From lib/screens/map_screen.dart)
        case 'interactive_map':
          return \`
            <div style="flex: 1; display: flex; flex-direction: column; gap: 12px; position: relative;">
              <!-- Map Filter Chips -->
              <div style="display: flex; gap: 10px; z-index: 20; padding: 4px 0;">
                <div style="padding: 10px 20px; border-radius: 18px; background: var(--cyan); color: #0A0E17; font-size: 16px; font-weight: 900;">
                  \${isHe ? 'הכל' : 'All'}
                </div>
                <div style="padding: 10px 20px; border-radius: 18px; background: rgba(20, 27, 45, 0.85); color: #94A3B8; font-size: 16px; font-weight: 800; border: 1px solid rgba(255,255,255,0.08);">
                  🎙️ \${isHe ? 'קוליים' : 'Voice'}
                </div>
                <div style="padding: 10px 20px; border-radius: 18px; background: rgba(20, 27, 45, 0.85); color: #94A3B8; font-size: 16px; font-weight: 800; border: 1px solid rgba(255,255,255,0.08);">
                  👥 \${isHe ? 'קבוצתיים' : 'Group'}
                </div>
              </div>

              <!-- Map Viewport Canvas -->
              <div style="flex: 1; border-radius: 26px; overflow: hidden; position: relative; border: 1px solid rgba(255,255,255,0.1); background: #070B14;">
                <!-- Roads Grid -->
                <div style="position: absolute; top: 0; left: 28%; width: 44px; height: 100%; background: rgba(255,255,255,0.04); border-left: 1px solid rgba(255,255,255,0.06); border-right: 1px solid rgba(255,255,255,0.06);"></div>
                <div style="position: absolute; top: 0; right: 26%; width: 52px; height: 100%; background: rgba(255,255,255,0.04); border-left: 1px solid rgba(255,255,255,0.06); border-right: 1px solid rgba(255,255,255,0.06);"></div>
                <div style="position: absolute; top: 32%; left: 0; width: 100%; height: 48px; background: rgba(255,255,255,0.04); border-top: 1px solid rgba(255,255,255,0.06); border-bottom: 1px solid rgba(255,255,255,0.06);"></div>
                <div style="position: absolute; top: 68%; left: 0; width: 100%; height: 56px; background: rgba(255,255,255,0.04); border-top: 1px solid rgba(255,255,255,0.06); border-bottom: 1px solid rgba(255,255,255,0.06);"></div>

                <!-- Sonar Rings from User Position -->
                <div style="position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); width: 320px; height: 320px; border-radius: 50%; border: 2px solid rgba(103, 232, 249, 0.35); box-shadow: 0 0 40px rgba(103, 232, 249, 0.2);"></div>
                <div style="position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); width: 580px; height: 580px; border-radius: 50%; border: 1.5px solid rgba(74, 158, 255, 0.2);"></div>
                <div style="position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); width: 880px; height: 880px; border-radius: 50%; border: 1px solid rgba(168, 85, 247, 0.15);"></div>

                <!-- User Center Dot -->
                <div style="position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); width: 28px; height: 28px; border-radius: 50%; background: var(--cyan); border: 4px solid #FFFFFF; box-shadow: 0 0 20px var(--cyan); z-index: 10;"></div>

                <!-- Map Pin 1: Cyan Voice -->
                <div style="position: absolute; top: 38%; left: 32%; display: flex; flex-direction: column; align-items: center; z-index: 15;">
                  <div style="background: rgba(10, 14, 23, 0.92); border: 2px solid var(--cyan); border-radius: 16px; padding: 6px 14px; font-size: 15px; font-weight: 800; color: #FFFFFF; box-shadow: 0 4px 16px rgba(0,0,0,0.6);">
                    🎙️ Dan • 45m
                  </div>
                  <div style="width: 0; height: 0; border-left: 7px solid transparent; border-right: 7px solid transparent; border-top: 8px solid var(--cyan);"></div>
                </div>

                <!-- Map Pin 2: Gold Tier 7 -->
                <div style="position: absolute; top: 26%; right: 28%; display: flex; flex-direction: column; align-items: center; z-index: 15;">
                  <div style="background: rgba(10, 14, 23, 0.92); border: 2px solid #FFD700; border-radius: 16px; padding: 6px 14px; font-size: 15px; font-weight: 800; color: #FFFFFF; box-shadow: 0 4px 16px rgba(0,0,0,0.6);">
                    ⭐ Tier 7 • 120m
                  </div>
                  <div style="width: 0; height: 0; border-left: 7px solid transparent; border-right: 7px solid transparent; border-top: 8px solid #FFD700;"></div>
                </div>

                <!-- Map Pin 3: Group Lock -->
                <div style="position: absolute; bottom: 22%; left: 42%; display: flex; flex-direction: column; align-items: center; z-index: 15;">
                  <div style="background: rgba(10, 14, 23, 0.92); border: 2px solid #EC4899; border-radius: 16px; padding: 6px 14px; font-size: 15px; font-weight: 800; color: #FFFFFF; box-shadow: 0 4px 16px rgba(0,0,0,0.6);">
                    👥 Group (2/3) • 180m
                  </div>
                  <div style="width: 0; height: 0; border-left: 7px solid transparent; border-right: 7px solid transparent; border-top: 8px solid #EC4899;"></div>
                </div>

                <!-- GPS Recenter Floating Action Button -->
                <div style="position: absolute; bottom: 24px; \${isHe ? 'left: 24px;' : 'right: 24px;'} width: 56px; height: 56px; border-radius: 50%; background: var(--bg-card); border: 1.5px solid var(--border-accent); display: flex; align-items: center; justify-content: center; font-size: 26px; box-shadow: 0 8px 24px rgba(0,0,0,0.5); z-index: 20;">
                  🎯
                </div>
              </div>
            </div>
          \`;

        // SCREEN 4: AUTHENTIC AUDIO PLAYER (From lib/screens/secret_detail_screen.dart)
        case 'audio_player':
          return \`
            <div style="flex: 1; display: flex; flex-direction: column; justify-content: space-between; padding: 6px 0;">
              <!-- Header Creator Info -->
              <div style="display: flex; flex-direction: column; align-items: center; text-align: center;">
                <div style="width: 140px; height: 140px; border-radius: 50%; background: linear-gradient(135deg, var(--cyan), var(--purple)); padding: 3px; box-shadow: 0 0 50px rgba(103, 232, 249, 0.45); margin-bottom: 16px;">
                  <div style="width: 100%; height: 100%; border-radius: 50%; background: #0A0E17; display: flex; align-items: center; justify-content: center; font-size: 46px; color: var(--cyan);">
                    🎙️
                  </div>
                </div>
                <div style="font-size: 32px; font-weight: 900; color: #FFFFFF; margin-bottom: 6px;">
                  \${isHe ? 'Hushhh לילי בעיר העתיקה' : 'Night Hushhh in the Old City'}
                </div>
                <div style="display: flex; align-items: center; gap: 10px;">
                  <span style="font-size: 19px; font-weight: 800; color: #94A3B8;">@AcousticNomad</span>
                  <span style="background: #EC4899; color: #FFF; font-size: 13px; font-weight: 800; padding: 4px 12px; border-radius: 12px;">Tier 8 • Gold</span>
                </div>
                <div class="distance-pill" style="margin-top: 12px;">
                  ✓ \${isHe ? 'נחשף במיקום הנוכחי • 12 מטר' : 'Revealed in current spot • 12m away'}
                </div>
              </div>

              <!-- High-res Waveform Card -->
              <div style="background: rgba(30, 38, 56, 0.65); border: 1.5px solid var(--border-accent); border-radius: 26px; padding: 26px; box-shadow: 0 16px 40px rgba(0,0,0,0.5);">
                <div class="audio-waveform-bars" style="height: 90px; gap: 6px; margin-bottom: 20px;">
                  \${generateWaveformHtml(24, 16, 90)}
                </div>

                <!-- Scrubber -->
                <div style="display: flex; align-items: center; justify-content: space-between; font-size: 18px; font-weight: 800; color: #94A3B8; margin-bottom: 22px;">
                  <span style="color: var(--cyan);">0:28</span>
                  <div style="flex: 1; height: 6px; background: rgba(255,255,255,0.12); border-radius: 10px; margin: 0 16px; position: relative;">
                    <div style="width: 52%; height: 100%; background: linear-gradient(90deg, var(--cyan), var(--purple)); border-radius: 10px;"></div>
                    <div style="position: absolute; top: -7px; left: 52%; width: 20px; height: 20px; border-radius: 50%; background: #FFFFFF; box-shadow: 0 0 10px var(--cyan);"></div>
                  </div>
                  <span>0:54</span>
                </div>

                <!-- Audio Controls -->
                <div style="display: flex; align-items: center; justify-content: center; gap: 32px;">
                  <div style="width: 54px; height: 54px; border-radius: 50%; background: rgba(255,255,255,0.06); display: flex; align-items: center; justify-content: center; font-size: 22px;">⏪</div>
                  <div style="width: 80px; height: 80px; border-radius: 50%; background: linear-gradient(135deg, var(--cyan), var(--blue), var(--purple)); display: flex; align-items: center; justify-content: center; box-shadow: 0 0 35px rgba(103, 232, 249, 0.5);">
                    <svg width="32" height="32" viewBox="0 0 24 24" fill="#0A0E17"><rect x="6" y="4" width="4" height="16"/><rect x="14" y="4" width="4" height="16"/></svg>
                  </div>
                  <div style="width: 54px; height: 54px; border-radius: 50%; background: rgba(255,255,255,0.06); display: flex; align-items: center; justify-content: center; font-size: 22px;">⏩</div>
                </div>
              </div>

              <!-- Reactions & Comments Bar -->
              <div style="display: flex; align-items: center; justify-content: space-around; background: rgba(255,255,255,0.04); border-radius: 20px; padding: 16px;">
                <div style="font-size: 18px; font-weight: 800; color: #EC4899;">❤️ 142</div>
                <div style="font-size: 18px; font-weight: 800; color: #94A3B8;">👎 2</div>
                <div style="font-size: 18px; font-weight: 800; color: var(--cyan);">💬 28</div>
                <div style="font-size: 18px; font-weight: 800; color: #FBBF24;">🔖 \${isHe ? 'שמור' : 'Save'}</div>
              </div>
            </div>
          \`;

        // SCREEN 5: AUTHENTIC PLANT/CREATE SCREEN (From lib/screens/create_screen.dart)
        case 'record_plant':
          return \`
            <div style="flex: 1; display: flex; flex-direction: column; justify-content: space-between; padding: 4px 0;">
              <!-- Authentic Cupertino Sliding Segmented Control (Text | Voice) -->
              <div class="flutter-segmented-control">
                <div class="seg-tab active">
                  🎙️ \${isHe ? 'קולי' : 'Voice'}
                </div>
                <div class="seg-tab">
                  ✍️ \${isHe ? 'טקסט' : 'Text'}
                </div>
              </div>

              <!-- Recording Stage with Pulsing Waves -->
              <div style="display: flex; flex-direction: column; align-items: center; justify-content: center; margin: 16px 0;">
                <div style="position: relative; width: 200px; height: 200px; display: flex; align-items: center; justify-content: center;">
                  <div style="position: absolute; width: 100%; height: 100%; border-radius: 50%; border: 3px solid var(--cyan); box-shadow: 0 0 45px var(--cyan); opacity: 0.65;"></div>
                  <div style="position: absolute; width: 130%; height: 130%; border-radius: 50%; border: 1.5px solid rgba(103, 232, 249, 0.3);"></div>
                  
                  <div style="width: 155px; height: 155px; border-radius: 50%; background: linear-gradient(135deg, var(--cyan), var(--blue), var(--purple)); display: flex; align-items: center; justify-content: center; box-shadow: 0 0 50px rgba(103, 232, 249, 0.55);">
                    <svg width="60" height="60" viewBox="0 0 24 24" fill="#0A0E17"><path d="M12 14c1.66 0 3-1.34 3-3V5c0-1.66-1.34-3-3-3S9 3.34 9 5v6c0 1.66 1.34 3 3 3z"/><path d="M17 11c0 2.76-2.24 5-5 5s-5-2.24-5-5H5c0 3.53 2.61 6.43 6 6.92V21h2v-3.08c3.39-.49 6-3.39 6-6.92h-2z"/></svg>
                  </div>
                </div>

                <div style="font-size: 26px; font-weight: 900; color: #FFFFFF; margin-top: 18px;">
                  \${isHe ? 'מקליט כעת... 0:24 / 1:00' : 'Recording now... 0:24 / 1:00'}
                </div>
                <div class="audio-waveform-bars" style="width: 65%; justify-content: center; margin-top: 12px;">
                  \${generateWaveformHtml(18)}
                </div>
              </div>

              <!-- Authentic Secret Type Selectors (Regular / Group) -->
              <div style="display: flex; flex-direction: column; gap: 12px;">
                <div style="font-size: 18px; font-weight: 800; color: #94A3B8;">
                  \${isHe ? 'סוג הסוד:' : 'Secret Type:'}
                </div>

                <!-- Regular Secret Radio (Active) -->
                <div style="background: rgba(30, 38, 56, 0.65); border: 1.5px solid var(--cyan); border-radius: 20px; padding: 18px 22px; display: flex; align-items: center; justify-content: space-between;">
                  <div>
                    <div style="font-size: 20px; font-weight: 900; color: #FFFFFF;">\${isHe ? 'סוד רגיל' : 'Regular Secret'}</div>
                    <div style="font-size: 14px; color: #94A3B8; margin-top: 2px;">\${isHe ? 'נחשף אוטומטית לכל מאזין העובר בטווח 50 מטר' : 'Reveals automatically to any listener within 50m'}</div>
                  </div>
                  <div style="width: 24px; height: 24px; border-radius: 50%; background: var(--cyan); display: flex; align-items: center; justify-content: center;">
                    <div style="width: 10px; height: 10px; border-radius: 50%; background: #0A0E17;"></div>
                  </div>
                </div>

                <!-- Group Secret Radio -->
                <div style="background: rgba(20, 27, 45, 0.6); border: 1px solid rgba(255, 255, 255, 0.08); border-radius: 20px; padding: 18px 22px; display: flex; align-items: center; justify-content: space-between;">
                  <div>
                    <div style="font-size: 20px; font-weight: 900; color: #FFFFFF;">\${isHe ? 'סוד קבוצתי' : 'Group Secret'}</div>
                    <div style="font-size: 14px; color: #94A3B8; margin-top: 2px;">\${isHe ? 'נחשף רק כש-3 משתתפים מתכנסים בו-זמנית' : 'Unlocks only when 3 participants gather together'}</div>
                  </div>
                  <div style="width: 24px; height: 24px; border-radius: 50%; border: 2px solid #94A3B8;"></div>
                </div>
              </div>

              <!-- Submit Plant Button (Matches Flutter ElevatedButton) -->
              <div class="flutter-primary-btn">
                <span>📍</span>
                <span>\${isHe ? 'הטמן סוד' : 'Plant Secret'}</span>
              </div>
            </div>
          \`;

        // SCREEN 6: AUTHENTIC GROUP HUSHHH SCREEN
        case 'group_hushhh':
          return \`
            <div style="flex: 1; display: flex; flex-direction: column; justify-content: space-between; padding: 4px 0;">
              <!-- Group Lock Header -->
              <div style="background: rgba(236, 72, 153, 0.12); border: 1.5px solid rgba(236, 72, 153, 0.4); border-radius: 22px; padding: 18px 22px; display: flex; align-items: center; gap: 16px;">
                <div style="font-size: 32px;">👥</div>
                <div>
                  <div style="font-size: 22px; font-weight: 900; color: #FFFFFF;">\${isHe ? 'סוד קבוצתי נעול' : 'Locked Group Secret'}</div>
                  <div style="font-size: 15px; color: #EC4899; font-weight: 700;">\${isHe ? 'דורש נוכחות פיזית משותפת לפתיחה' : 'Requires simultaneous presence to unlock'}</div>
                </div>
              </div>

              <!-- Collaborative Radar Stage -->
              <div style="background: rgba(30, 38, 56, 0.65); border: 1.5px solid var(--border-accent); border-radius: 28px; padding: 32px 22px; display: flex; flex-direction: column; align-items: center; text-align: center; position: relative;">
                <div style="width: 120px; height: 120px; border-radius: 50%; background: linear-gradient(135deg, var(--pink), var(--purple)); display: flex; align-items: center; justify-content: center; box-shadow: 0 0 50px rgba(236, 72, 153, 0.45); margin-bottom: 20px;">
                  <svg width="52" height="52" viewBox="0 0 24 24" fill="#FFFFFF"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
                </div>

                <div style="font-size: 26px; font-weight: 900; color: #FFFFFF; margin-bottom: 6px;">
                  \${isHe ? 'נדרשים 3 אנשים יחד במקום' : '3 People Required Together'}
                </div>
                <div style="font-size: 20px; font-weight: 800; color: var(--cyan); margin-bottom: 22px;">
                  \${isHe ? '2 מתוך 3 כבר כאן!' : '2 out of 3 already here!'}
                </div>

                <!-- 3 User Slots -->
                <div style="display: flex; align-items: center; justify-content: center; gap: 24px; margin-bottom: 24px;">
                  <div style="position: relative;">
                    <div style="width: 66px; height: 66px; border-radius: 50%; border: 3px solid var(--green); background: #1E293B; display: flex; align-items: center; justify-content: center; font-size: 26px;">👤</div>
                    <div style="position: absolute; bottom: -3px; right: -3px; width: 22px; height: 22px; border-radius: 50%; background: var(--green); display: flex; align-items: center; justify-content: center; font-size: 13px; color: #000; font-weight: 900;">✓</div>
                  </div>

                  <div style="position: relative;">
                    <div style="width: 66px; height: 66px; border-radius: 50%; border: 3px solid var(--green); background: #1E293B; display: flex; align-items: center; justify-content: center; font-size: 26px;">👤</div>
                    <div style="position: absolute; bottom: -3px; right: -3px; width: 22px; height: 22px; border-radius: 50%; background: var(--green); display: flex; align-items: center; justify-content: center; font-size: 13px; color: #000; font-weight: 900;">✓</div>
                  </div>

                  <div style="position: relative;">
                    <div style="width: 66px; height: 66px; border-radius: 50%; border: 3px dashed var(--pink); background: rgba(236, 72, 153, 0.12); display: flex; align-items: center; justify-content: center; font-size: 24px;">?</div>
                    <div style="position: absolute; bottom: -3px; right: -3px; width: 22px; height: 22px; border-radius: 50%; background: var(--pink); display: flex; align-items: center; justify-content: center; font-size: 12px; color: #FFF; font-weight: 900;">⏳</div>
                  </div>
                </div>

                <!-- Proximity Info -->
                <div style="background: rgba(0,0,0,0.45); border-radius: 16px; padding: 12px 20px; font-size: 16px; color: #CBD5E1; font-weight: 600;">
                  📍 \${isHe ? 'המשתמש השלישי במרחק 18 מטרים - בדרך אליכם!' : 'The 3rd listener is 18m away - walking towards you!'}
                </div>
              </div>

              <!-- Join Button -->
              <div class="flutter-primary-btn" style="background: linear-gradient(135deg, var(--pink), var(--purple)); color: #FFFFFF;">
                <span>🔓</span>
                <span>\${isHe ? 'הצטרף לפתיחה משותפת' : 'Join Group Unlock'}</span>
              </div>
            </div>
          \`;

        // SCREEN 7: AUTHENTIC PROFILE / TIERS SCREEN (From lib/screens/profile_screen.dart)
        case 'clout_tiers':
          return \`
            <div style="flex: 1; display: flex; flex-direction: column; justify-content: space-between; padding: 4px 0;">
              <!-- Profile Header Card -->
              <div class="flutter-secret-card" style="--tier-color: #A855F7; --tier-glow: rgba(168, 85, 247, 0.35);">
                <div style="display: flex; align-items: center; gap: 18px;">
                  <div style="width: 80px; height: 80px; border-radius: 50%; background: linear-gradient(135deg, #EC4899, #A855F7); padding: 3px; box-shadow: 0 0 25px rgba(168, 85, 247, 0.5);">
                    <div style="width: 100%; height: 100%; border-radius: 50%; background: #0A0E17; display: flex; align-items: center; justify-content: center; font-size: 34px;">
                      👑
                    </div>
                  </div>
                  <div>
                    <div style="font-size: 26px; font-weight: 900; color: #FFFFFF;">@SonicMaster</div>
                    <div style="display: flex; align-items: center; gap: 8px; margin-top: 4px;">
                      <span style="background: #A855F7; color: #FFF; font-size: 13px; font-weight: 800; padding: 3px 12px; border-radius: 12px;">Tier 5 • Maestro</span>
                      <span style="color: var(--cyan); font-size: 15px; font-weight: 700;">★ 2,450 Clout</span>
                    </div>
                  </div>
                </div>

                <!-- Clout Progress Bar -->
                <div style="display: flex; flex-direction: column; gap: 8px;">
                  <div style="display: flex; justify-content: space-between; font-size: 15px; font-weight: 700; color: #94A3B8;">
                    <span>\${isHe ? 'התקדמות ל-Tier 6 (Virtuoso)' : 'Progress to Tier 6 (Virtuoso)'}</span>
                    <span style="color: #FFFFFF;">2,450 / 3,000</span>
                  </div>
                  <div style="width: 100%; height: 10px; border-radius: 6px; background: rgba(255,255,255,0.1); overflow: hidden;">
                    <div style="width: 82%; height: 100%; border-radius: 6px; background: linear-gradient(90deg, var(--cyan), var(--purple));"></div>
                  </div>
                </div>

                <!-- Stats Row -->
                <div style="display: flex; justify-content: space-around; border-top: 1px solid rgba(255,255,255,0.08); padding-top: 14px;">
                  <div style="text-align: center;">
                    <div style="font-size: 22px; font-weight: 900; color: #FFFFFF;">14</div>
                    <div style="font-size: 13px; color: #94A3B8;">\${isHe ? 'הוטמנו' : 'Planted'}</div>
                  </div>
                  <div style="text-align: center;">
                    <div style="font-size: 22px; font-weight: 900; color: #FFFFFF;">89</div>
                    <div style="font-size: 13px; color: #94A3B8;">\${isHe ? 'נחשפו' : 'Revealed'}</div>
                  </div>
                  <div style="text-align: center;">
                    <div style="font-size: 22px; font-weight: 900; color: #FFFFFF;">342</div>
                    <div style="font-size: 13px; color: #94A3B8;">\${isHe ? 'עוקבים' : 'Followers'}</div>
                  </div>
                  <div style="text-align: center;">
                    <div style="font-size: 22px; font-weight: 900; color: #FFFFFF;">120</div>
                    <div style="font-size: 13px; color: #94A3B8;">\${isHe ? 'במעקב' : 'Following'}</div>
                  </div>
                </div>
              </div>

              <!-- Segmented Tabs (My Secrets / Saved) -->
              <div class="flutter-segmented-control">
                <div class="seg-tab active">\${isHe ? 'הסודות שלי' : 'My Secrets'}</div>
                <div class="seg-tab">\${isHe ? 'סודות שמורים' : 'Saved Vault'}</div>
              </div>

              <!-- Quick Mini Feed Item -->
              <div class="flutter-secret-card" style="padding: 16px 20px;">
                <div style="display: flex; align-items: center; justify-content: space-between;">
                  <span style="font-weight: 800; color: #FFFFFF; font-size: 18px;">\${isHe ? 'מנגינת חצות בכיכר' : 'Midnight Melody at the Square'}</span>
                  <span class="distance-pill" style="font-size: 13px; padding: 4px 12px;">❤️ 56</span>
                </div>
              </div>
            </div>
          \`;

        // SCREEN 8: AUTHENTIC FOLLOWING SCREEN (From lib/screens/following_screen.dart)
        case 'following_feed':
          return \`
            <div style="flex: 1; display: flex; flex-direction: column; gap: 16px;">
              <!-- Search Bar Matching Flutter TextField -->
              <div style="background: rgba(30, 38, 56, 0.65); border: 1px solid rgba(255,255,255,0.1); border-radius: 18px; padding: 14px 20px; display: flex; align-items: center; gap: 14px;">
                <span style="font-size: 20px; color: #94A3B8;">🔍</span>
                <span style="font-size: 17px; color: #64748B;">\${isHe ? 'חפש יוצרים או חברים...' : 'Search creators or friends...'}</span>
              </div>

              <!-- Followed Creators Avatar Row -->
              <div>
                <div style="font-size: 17px; font-weight: 800; color: #94A3B8; margin-bottom: 10px;">
                  \${isHe ? 'יוצרים במעקב:' : 'Followed Creators:'}
                </div>
                <div style="display: flex; gap: 16px; overflow: hidden;">
                  <div style="display: flex; flex-direction: column; align-items: center; gap: 6px;">
                    <div style="width: 60px; height: 60px; border-radius: 50%; border: 2.5px solid #67E8F9; background: #1E293B; display: flex; align-items: center; justify-content: center; font-size: 24px; color: #FFF; font-weight: 800;">M</div>
                    <span style="font-size: 13px; font-weight: 700; color: #CBD5E1;">@Maya</span>
                  </div>
                  <div style="display: flex; flex-direction: column; align-items: center; gap: 6px;">
                    <div style="width: 60px; height: 60px; border-radius: 50%; border: 2.5px solid #A855F7; background: #1E293B; display: flex; align-items: center; justify-content: center; font-size: 24px; color: #FFF; font-weight: 800;">D</div>
                    <span style="font-size: 13px; font-weight: 700; color: #CBD5E1;">@Dan</span>
                  </div>
                  <div style="display: flex; flex-direction: column; align-items: center; gap: 6px;">
                    <div style="width: 60px; height: 60px; border-radius: 50%; border: 2.5px solid #FFD700; background: #1E293B; display: flex; align-items: center; justify-content: center; font-size: 24px; color: #FFF; font-weight: 800;">S</div>
                    <span style="font-size: 13px; font-weight: 700; color: #CBD5E1;">@Sonic</span>
                  </div>
                  <div style="display: flex; flex-direction: column; align-items: center; gap: 6px;">
                    <div style="width: 60px; height: 60px; border-radius: 50%; border: 2.5px solid #EC4899; background: #1E293B; display: flex; align-items: center; justify-content: center; font-size: 24px; color: #FFF; font-weight: 800;">E</div>
                    <span style="font-size: 13px; font-weight: 700; color: #CBD5E1;">@Echo</span>
                  </div>
                </div>
              </div>

              <!-- Followed Secret Feed Item -->
              <div class="flutter-secret-card" style="--tier-color: #67E8F9; --tier-glow: rgba(103, 232, 249, 0.3);">
                <div class="card-top-row">
                  <div class="creator-info">
                    <div class="creator-avatar-ring">
                      <div class="creator-avatar-inner">M</div>
                    </div>
                    <div class="creator-names">
                      <div class="creator-name-row">
                        <span class="creator-username">@Maya</span>
                        <span class="time-ago">\${isHe ? 'לפני 25 דקות' : '25m ago'}</span>
                      </div>
                      <span class="secret-type-badge">\${isHe ? 'סוד קולי חדש' : 'New Voice Secret'}</span>
                    </div>
                  </div>
                  <span class="distance-pill">📍 \${isHe ? '70 מטר' : '70m away'}</span>
                </div>

                <div class="audio-player-box">
                  <div class="play-btn-circle">
                    <svg width="22" height="22" viewBox="0 0 24 24" fill="#0A0E17"><polygon points="5 3 19 12 5 21 5 3"/></svg>
                  </div>
                  <div class="audio-waveform-bars">
                    \${generateWaveformHtml(20)}
                  </div>
                  <span style="font-size: 18px; font-weight: 800; color: #E2E8F0;">0:42</span>
                </div>
              </div>
            </div>
          \`;

        // SCREEN 9: AUTHENTIC SMART NOTIFICATIONS (From lib/screens/notifications_settings_screen.dart)
        case 'smart_notifications':
          return \`
            <div style="flex: 1; display: flex; flex-direction: column; gap: 16px;">
              <!-- Proximity Notification Toast Pop-in -->
              <div style="background: rgba(20, 27, 45, 0.95); border: 2px solid var(--cyan); border-radius: 20px; padding: 16px 20px; box-shadow: 0 10px 30px rgba(103, 232, 249, 0.3); display: flex; align-items: center; gap: 16px;">
                <div style="width: 46px; height: 46px; border-radius: 50%; background: linear-gradient(135deg, var(--cyan), var(--purple)); display: flex; align-items: center; justify-content: center; font-size: 22px;">🔔</div>
                <div style="flex: 1;">
                  <div style="font-size: 19px; font-weight: 900; color: #FFFFFF;">Hushhh • \${isHe ? 'התראת קרבה' : 'Proximity Alert'}</div>
                  <div style="font-size: 15px; color: var(--cyan); font-weight: 700;">
                    \${isHe ? '@SonicMaster הטמין סוד 45 מטר ממך!' : '@SonicMaster planted a secret 45m from you!'}
                  </div>
                </div>
              </div>

              <!-- Master Switch (SwitchListTile) -->
              <div class="flutter-secret-card" style="display: flex; flex-direction: row; align-items: center; justify-content: space-between; padding: 18px 22px;">
                <div>
                  <div style="font-size: 21px; font-weight: 900; color: #FFFFFF;">\${isHe ? 'הפעל התראות חכמות' : 'Enable Smart Notifications'}</div>
                  <div style="font-size: 14px; color: #94A3B8; margin-top: 2px;">\${isHe ? 'קבל עדכונים אקוסטיים בזמן אמת' : 'Receive real-time acoustic updates'}</div>
                </div>
                <!-- iOS Style Switch ON -->
                <div style="width: 58px; height: 32px; background: var(--cyan); border-radius: 20px; position: relative; box-shadow: 0 0 14px rgba(103, 232, 249, 0.5);">
                  <div style="width: 26px; height: 26px; border-radius: 50%; background: #0A0E17; position: absolute; top: 3px; \${isHe ? 'left: 4px;' : 'right: 4px;'}"></div>
                </div>
              </div>

              <!-- Detailed Fine-grained Controls -->
              <div style="display: flex; flex-direction: column; gap: 10px;">
                <!-- Control 1 -->
                <div class="flutter-secret-card" style="display: flex; flex-direction: row; align-items: center; justify-content: space-between; padding: 16px 20px;">
                  <div>
                    <div style="font-size: 18px; font-weight: 800; color: #FFFFFF;">\${isHe ? 'סודות של יוצרים במעקב' : 'Followed Creators Secrets'}</div>
                    <div style="font-size: 13px; color: #94A3B8;">\${isHe ? 'התראה כשיוצר שאתה עוקב אחריו מטמין סוד' : 'Notify when a creator you follow plants a secret'}</div>
                  </div>
                  <div style="width: 50px; height: 28px; background: var(--cyan); border-radius: 20px; position: relative;">
                    <div style="width: 22px; height: 22px; border-radius: 50%; background: #0A0E17; position: absolute; top: 3px; \${isHe ? 'left: 4px;' : 'right: 4px;'}"></div>
                  </div>
                </div>

                <!-- Control 2 -->
                <div class="flutter-secret-card" style="display: flex; flex-direction: row; align-items: center; justify-content: space-between; padding: 16px 20px;">
                  <div>
                    <div style="font-size: 18px; font-weight: 800; color: #FFFFFF;">\${isHe ? 'פתיחת סודות קבוצתיים' : 'Group Secret Unlocks'}</div>
                    <div style="font-size: 13px; color: #94A3B8;">\${isHe ? 'התראה כשמשתמש נוסף מתקרב לפתיחה' : 'Notify when another user approaches for unlock'}</div>
                  </div>
                  <div style="width: 50px; height: 28px; background: var(--cyan); border-radius: 20px; position: relative;">
                    <div style="width: 22px; height: 22px; border-radius: 50%; background: #0A0E17; position: absolute; top: 3px; \${isHe ? 'left: 4px;' : 'right: 4px;'}"></div>
                  </div>
                </div>

                <!-- Control 3 -->
                <div class="flutter-secret-card" style="display: flex; flex-direction: row; align-items: center; justify-content: space-between; padding: 16px 20px;">
                  <div>
                    <div style="font-size: 18px; font-weight: 800; color: #FFFFFF;">\${isHe ? 'התראות רדאר ורטט קרבה' : 'Proximity Radar & Vibration'}</div>
                    <div style="font-size: 13px; color: #94A3B8;">\${isHe ? 'רטט כשאתה חולף ליד סוד במרחב' : 'Vibrate when passing near a secret'}</div>
                  </div>
                  <div style="width: 50px; height: 28px; background: var(--cyan); border-radius: 20px; position: relative;">
                    <div style="width: 22px; height: 22px; border-radius: 50%; background: #0A0E17; position: absolute; top: 3px; \${isHe ? 'left: 4px;' : 'right: 4px;'}"></div>
                  </div>
                </div>
              </div>
            </div>
          \`;

        // SCREEN 10: AUTHENTIC SAVED VAULT SCREEN (From lib/screens/profile_screen.dart tab 1)
        case 'saved_vault':
          return \`
            <div style="flex: 1; display: flex; flex-direction: column; gap: 14px;">
              <!-- Proximity Banner -->
              <div style="background: rgba(103, 232, 249, 0.1); border: 1.5px solid var(--border-accent); border-radius: 18px; padding: 14px 20px; display: flex; align-items: center; gap: 14px;">
                <span style="font-size: 22px;">🔔</span>
                <span style="font-size: 16px; font-weight: 800; color: #F1F5F9;">
                  \${isHe ? 'התראת קרבה פעילה על כל הסודות השמורים' : 'Proximity radar active for all saved secrets'}
                </span>
              </div>

              <!-- Filter Chips -->
              <div style="display: flex; gap: 10px;">
                <div style="padding: 10px 18px; border-radius: 16px; background: var(--cyan); color: #0A0E17; font-size: 16px; font-weight: 900;">
                  \${isHe ? 'הכל (14)' : 'All (14)'}
                </div>
                <div style="padding: 10px 18px; border-radius: 16px; background: rgba(20, 27, 45, 0.85); color: #94A3B8; font-size: 16px; font-weight: 800; border: 1px solid rgba(255,255,255,0.08);">
                  🎙️ \${isHe ? 'קוליים (10)' : 'Voice (10)'}
                </div>
                <div style="padding: 10px 18px; border-radius: 16px; background: rgba(20, 27, 45, 0.85); color: #94A3B8; font-size: 16px; font-weight: 800; border: 1px solid rgba(255,255,255,0.08);">
                  👥 \${isHe ? 'קבוצתיים (4)' : 'Group (4)'}
                </div>
              </div>

              <!-- Saved Card 1 -->
              <div class="flutter-secret-card" style="--tier-color: #00F0FF;">
                <div class="card-top-row">
                  <div class="creator-info">
                    <span style="font-size: 26px;">🔖</span>
                    <div>
                      <div class="creator-username">@SoundSeeker</div>
                      <div class="time-ago">\${isHe ? 'לפני יומיים • נשמר להאזנה' : '2 days ago • Saved'}</div>
                    </div>
                  </div>
                  <span class="distance-pill" style="background: rgba(52, 211, 153, 0.15); border-color: var(--green); color: var(--green);">
                    📍 \${isHe ? '80 מטר' : '80m away'}
                  </span>
                </div>

                <div class="audio-player-box">
                  <div class="play-btn-circle">
                    <svg width="22" height="22" viewBox="0 0 24 24" fill="#0A0E17"><polygon points="5 3 19 12 5 21 5 3"/></svg>
                  </div>
                  <div class="audio-waveform-bars">
                    \${generateWaveformHtml(16)}
                  </div>
                  <span style="font-size: 17px; font-weight: 800; color: #CBD5E1;">0:38</span>
                </div>
              </div>

              <!-- Saved Card 2 -->
              <div class="flutter-secret-card">
                <div class="card-top-row">
                  <div class="creator-info">
                    <span style="font-size: 26px;">👥</span>
                    <div>
                      <div class="creator-username">\${isHe ? 'סוד קבוצתי - פארק הירקון' : 'Group Secret - Central Park'}</div>
                      <div class="time-ago">\${isHe ? 'נדרשים 3 אנשים • שמור' : '3 people required • Saved'}</div>
                    </div>
                  </div>
                  <span class="distance-pill">📍 1.2km</span>
                </div>
                <div style="font-size: 16px; color: #94A3B8; line-height: 1.4;">
                  \${isHe ? 'התראה תופעל אוטומטית כשתגיע לטווח 200 מטר מהמיקום' : 'Alert triggers automatically when within 200m'}
                </div>
              </div>
            </div>
          \`;

        default:
          return \`<div>Screen \${screenId}</div>\`;
      }
    }

    // BUILD ENTIRE DEVICE MOCKUP
    function buildDeviceHtml(deviceType, screenId, lang) {
      const isIphone = deviceType === 'iphone';
      const isHe = lang === 'he';
      const isFullScreen = screenData.isFullScreen;
      const screenHtml = getScreenBodyContent(screenId, lang);
      const activeTab = screenData.activeTab !== undefined ? screenData.activeTab : 0;

      // Authentic Flutter Screen Titles
      const screenTitles = {
        'welcome': '',
        'nearby_feed': isHe ? 'פיד Hushhh' : 'Hushhh Feed',
        'interactive_map': isHe ? 'מפת Hushhh' : 'Hushhh Map',
        'audio_player': isHe ? 'האזנה ל-Hushhh' : 'Audio Player',
        'record_plant': isHe ? 'הטמן סוד' : 'Plant Secret',
        'group_hushhh': isHe ? 'סוד קבוצתי' : 'Group Secret',
        'clout_tiers': isHe ? 'פרופיל ודרגות' : 'Profile & Tiers',
        'following_feed': isHe ? 'עוקבים' : 'Following',
        'smart_notifications': isHe ? 'התראות חכמות' : 'Notifications',
        'saved_vault': isHe ? 'סודות שמורים' : 'Saved Vault'
      };

      const appBarTitle = screenTitles[screenId] || '';

      // Authentic Flutter Top Bar (main.dart top_banner2.png + AppBar)
      const topBarHtml = isFullScreen ? '' : \`
        <!-- Persistent Flutter App Header (top_banner2.png) -->
        <div class="flutter-top-header">
          <img src="assets/top_banner2.png" class="flutter-top-banner-img" alt="Hushhh">
          <div class="flutter-back-pill">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#94A3B8" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M15 18l-6-6 6-6"/></svg>
            <span>Back</span>
          </div>
        </div>

        <!-- Authentic Flutter AppBar -->
        <div class="flutter-app-bar">
          <div class="flutter-app-bar-left">
            <div class="flutter-menu-btn">☰</div>
            <div class="flutter-app-bar-title">\${appBarTitle}</div>
          </div>
          <div class="flutter-app-bar-actions">
            <div class="flutter-action-icon">
              🔔
              <div class="unread-dot"></div>
            </div>
            <div class="flutter-action-icon">🔄</div>
          </div>
        </div>
      \`;

      // Authentic Flutter AppShell Bottom Navigation Bar
      const bottomNavHtml = isFullScreen ? '' : \`
        <div class="flutter-bottom-nav">
          <!-- Feed Tab -->
          <div class="flutter-nav-tab \${activeTab === 0 ? 'active' : ''}">
            <svg width="28" height="28" viewBox="0 0 256 256" fill="currentColor">
              <path d="M104,40H56A16,16,0,0,0,40,56v48a16,16,0,0,0,16,16h48a16,16,0,0,0,16-16V56A16,16,0,0,0,104,40ZM104,136H56a16,16,0,0,0-16,16v48a16,16,0,0,0,16,16h48a16,16,0,0,0,16-16V152A16,16,0,0,0,104,136ZM200,40H152a16,16,0,0,0-16,16v48a16,16,0,0,0,16,16h48a16,16,0,0,0,16-16V56A16,16,0,0,0,200,40ZM200,136H152a16,16,0,0,0-16,16v48a16,16,0,0,0,16,16h48a16,16,0,0,0,16-16V152A16,16,0,0,0,200,136Z"/>
            </svg>
            <span>\${isHe ? 'פיד' : 'Feed'}</span>
          </div>

          <!-- Map Tab -->
          <div class="flutter-nav-tab \${activeTab === 1 ? 'active' : ''}">
            <svg width="28" height="28" viewBox="0 0 256 256" fill="currentColor">
              <path d="M228.92,49.69a8,8,0,0,0-6.86-1.45L160.93,63.51,99.94,48.26a8,8,0,0,0-3.88,0L34.06,63.76A8,8,0,0,0,28,71.52V207.4a8,8,0,0,0,10,7.76l61.07-15.27,61,15.25a8.05,8.05,0,0,0,3.88,0l62-15.5A8,8,0,0,0,232,187V51.12A8,8,0,0,0,228.92,49.69ZM92,62.88l56,14V193.12l-56-14ZM44,77.34l32-8V195.46l-32,8ZM216,178.66l-32,8V60.54l32-8Z"/>
            </svg>
            <span>\${isHe ? 'מפה' : 'Map'}</span>
          </div>

          <!-- Center Plant Floating Circle Button -->
          <div class="flutter-nav-center-btn">
            <svg width="34" height="34" viewBox="0 0 256 256" fill="#FFFFFF">
              <path d="M128,24A104,104,0,1,0,232,128,104.11,104.11,0,0,0,128,24Zm0,192a88,88,0,1,1,88-88A88.1,88.1,0,0,1,128,216Zm48-88a8,8,0,0,1-8,8H136v32a8,8,0,0,1-16,0V136H88a8,8,0,0,1,0-16h32V88a8,8,0,0,1,16,0v32h32A8,8,0,0,1,176,128Z"/>
            </svg>
          </div>

          <!-- Following Tab -->
          <div class="flutter-nav-tab \${activeTab === 3 ? 'active' : ''}">
            <svg width="28" height="28" viewBox="0 0 256 256" fill="currentColor">
              <path d="M117.25,157.92a60,60,0,1,0-66.5,0A95.83,95.83,0,0,0,3.53,195.63a8,8,0,1,0,13.4,8.74,80,80,0,0,1,134.14,0,8,8,0,0,0,13.4-8.74A95.83,95.83,0,0,0,117.25,157.92ZM40,108a44,44,0,1,1,44,44A44.05,44.05,0,0,1,40,108Zm210.14,98.74a8,8,0,0,1-11.07-2.33A79.83,79.83,0,0,0,172,168a8,8,0,0,1,0-16,44,44,0,1,0-16.34-84.87,8,8,0,1,1-5.94-14.85,60,60,0,1,1,25.41,114.77,95.73,95.73,0,0,1,73.14,37.62A8,8,0,0,1,250.14,206.74Z"/>
            </svg>
            <span>\${isHe ? 'עוקבים' : 'Following'}</span>
          </div>

          <!-- Profile Tab -->
          <div class="flutter-nav-tab \${activeTab === 4 ? 'active' : ''}">
            <svg width="28" height="28" viewBox="0 0 256 256" fill="currentColor">
              <path d="M128,24A104,104,0,1,0,232,128,104.11,104.11,0,0,0,128,24ZM74.08,197.5a64,64,0,0,1,107.84,0,87.83,87.83,0,0,1-107.84,0ZM96,120a32,32,0,1,1,32,32A32,32,0,0,1,96,120Zm97.76,66.41a79.66,79.66,0,0,0-36.06-28.75,48,48,0,1,0-59.4,0,79.66,79.66,0,0,0-36.06,28.75,88,88,0,1,1,131.52,0Z"/>
            </svg>
            <span>\${isHe ? 'פרופיל' : 'Profile'}</span>
          </div>
        </div>
      \`;

      if (isIphone) {
        return \`
          <div class="device-frame-iphone">
            <!-- Dynamic Island -->
            <div class="iphone-island-container">
              <div class="island-camera"></div>
              <div class="island-sensor"></div>
            </div>

            <!-- iOS Status Bar -->
            <div class="ios-status-bar">
              <span class="ios-status-time">9:41</span>
              <div class="ios-status-icons">
                <svg width="24" height="18" viewBox="0 0 24 16" fill="white"><rect x="1" y="10" width="3" height="6" rx="1"/><rect x="7" y="7" width="3" height="9" rx="1"/><rect x="13" y="4" width="3" height="12" rx="1"/><rect x="19" y="1" width="3" height="15" rx="1"/></svg>
                <span style="font-size: 17px; font-weight: 800; font-family: sans-serif;">5G</span>
                <svg width="30" height="16" viewBox="0 0 28 14" fill="white"><rect x="1" y="1" width="22" height="12" rx="3" fill="none" stroke="white" stroke-width="1.5"/><rect x="3" y="3" width="16" height="8" rx="1.5"/><path d="M25 5v4" stroke="white" stroke-width="1.5" stroke-linecap="round"/></svg>
              </div>
            </div>

            <!-- App Screen Viewport -->
            <div class="app-screen-viewport">
              \${topBarHtml}
              <div class="flutter-screen-content">
                \${screenHtml}
              </div>
              \${bottomNavHtml}
            </div>

            <!-- iOS Home Bar -->
            <div class="ios-home-bar"></div>
          </div>
        \`;
      } else {
        // SAMSUNG GALAXY S24 ULTRA
        return \`
          <div class="device-frame-samsung">
            <!-- Centered Punch Hole Camera -->
            <div class="samsung-punch-hole"></div>

            <!-- One UI Status Bar -->
            <div class="samsung-status-bar">
              <span class="samsung-status-time">12:00</span>
              <div class="samsung-status-icons">
                <span style="font-size: 16px; font-weight: 800; font-family: sans-serif;">5G</span>
                <svg width="22" height="18" viewBox="0 0 24 16" fill="white"><rect x="1" y="10" width="3" height="6" rx="1"/><rect x="7" y="7" width="3" height="9" rx="1"/><rect x="13" y="4" width="3" height="12" rx="1"/><rect x="19" y="1" width="3" height="15" rx="1"/></svg>
                <svg width="20" height="16" viewBox="0 0 24 18" fill="white"><path d="M12 4C7.3 4 3.1 6.1.4 9.6l10.8 13.5c.4.5 1.2.5 1.6 0L23.6 9.6C20.9 6.1 16.7 4 12 4z"/></svg>
                <span style="font-size: 16px; font-weight: 800;">98%</span>
              </div>
            </div>

            <!-- App Screen Viewport -->
            <div class="app-screen-viewport">
              \${topBarHtml}
              <div class="flutter-screen-content">
                \${screenHtml}
              </div>
              \${bottomNavHtml}
            </div>

            <!-- Samsung Nav Bar -->
            <div class="samsung-nav-bar"></div>
          </div>
        \`;
      }
    }

    document.getElementById('device-stage').innerHTML = buildDeviceHtml(device, screenData.id, lang);
  </script>
</body>
</html>
`;

fs.writeFileSync('marketing/render_engine.html', engineContent, 'utf8');
console.log('Successfully wrote authentic render_engine.html!');
