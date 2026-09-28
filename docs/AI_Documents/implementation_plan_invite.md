# Goal Description

Implement a native cross-platform "Invite Friends" feature via the share drawer, and a smart pop-up that appears after 2 minutes of app usage encouraging the user to invite friends.

## User Review Required

> [!IMPORTANT]
> **Dependencies Addition:** I will be adding the `share_plus` package to the project to handle the native share drawer functionality for both iOS and Android.

> [!NOTE]
> **Popup Logic:** The 2-minute timer will run in the background while the user is logged into the app. Once 2 minutes have passed, it will show the popup. If the user clicks "Don't show again", this preference will be saved locally so they are never bothered again.

Are you good with these additions?

## Proposed Changes

### Configuration
#### [MODIFY] pubspec.yaml
- Add `share_plus: ^10.0.0` (or latest compatible version) under dependencies.

### Localization
#### [MODIFY] lib/l10n/app_en.arb & lib/l10n/app_he.arb
- Add new localized strings:
  - `inviteFriends`: "Invite Friends" / "הזמינו חברים"
  - `inviteMessage`: "Enjoying hushhh? Invite friends, create group hushhh and wait for them to open them" / "נהנים ב-hushhh? הזמינו חברים, צרו hushhh קבוצתיים והמתינו שיפתחו אותם"
  - `dontShowAgain`: "Don't show again" / "אל תציג שוב"
  - `shareAppText`: "Join me on HUSH! The geo-acoustic social network. Download now: [link]" / "הצטרפו אליי ל-HUSH! הרשת החברתית הגיאו-אקוסטית. הורידו עכשיו: [link]"

### UI / Screens
#### [MODIFY] lib/widgets/hush_drawer.dart
- Add a new `ListTile` for "Invite Friends" with an appropriate icon (e.g., share or user-plus).
- When tapped, trigger `Share.share(l10n.shareAppText)`.

#### [MODIFY] lib/screens/app_shell.dart
- Add a `Timer` in `initState` that runs for 2 minutes.
- Add `SharedPreferences` check to ensure the popup hasn't been permanently dismissed.
- When the timer completes, display a customized `AlertDialog` with the invite message.
- Add "Don't show again" button (saves to SharedPreferences and closes).
- Add "Invite Friends" button (opens the native share drawer and optionally saves to SharedPreferences).

## Verification Plan

### Automated Tests
- Build and run the app to ensure `share_plus` does not cause build conflicts.
- Check `pubspec.yaml` resolution.

### Manual Verification
- Open the side menu and click "Invite Friends" -> Verify the native share drawer opens.
- Wait for 2 minutes on the main screen -> Verify the popup appears.
- Click "Don't show again" -> Restart the app, wait 2 minutes -> Verify it does NOT appear again.
