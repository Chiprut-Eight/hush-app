# Invite Friends Feature Walkthrough

The "Invite Friends" functionality and the smart 2-minute timer have been fully implemented!

## What Changed

### 1. New Dependency (`share_plus`)
- We added the `share_plus` package which allows the app to securely tap into the native operating system's share drawer (works seamlessly on both iOS and Android).

### 2. Side Menu Button
- Opened the `hush_drawer.dart` menu and added a new **"Invite Friends"** button (with an 'add user' icon).
- Tapping this immediately opens the native share drawer, prepopulated with our custom marketing text and a link to download the app.

### 3. Smart 2-Minute Timer
- In the main `AppShell` (the screen that wraps the Feed, Map, etc.), we added a background timer.
- When you log in, the timer starts counting. Exactly **2 minutes** later, it triggers a custom popup message.
- The popup asks the user if they're enjoying Hushhh and encourages them to invite friends.

### 4. Smart Dismissal
- If the user taps **"Don't show again"**, we use `SharedPreferences` to save a flag (`hasSeenInvitePopup`) directly on their device. 
- The timer checks this flag immediately when the app starts. If it's true, the timer never runs, ensuring we never bother them again!

## How to Test
1. Rebuild the Flutter app on your device (since we added a new package, a fresh build is required).
2. Open the side menu and click **"Invite Friends"** to verify the iOS/Android share sheet opens with the correct Hebrew/English text.
3. Restart the app, stay on the main feed or map, and wait for exactly 2 minutes.
4. Verify the popup appears.
5. Click **"Don't show again"**. 
6. Restart the app and wait 2 minutes again—verify the popup does *not* appear.
