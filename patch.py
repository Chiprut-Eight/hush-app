import re

with open('lib/screens/app_shell.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Remove the case 0 from app_shell title setting, so FeedScreen is the sole authority
content = content.replace("case 0: title = l10n.feedTitle; break;", "case 0: /* handled by FeedScreen */ return;")

# Fix the popup layout overflow: wrap the buttons in an OverflowBar
old_row = '''              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('hasSeenInvitePopup', true);
                      AnalyticsService().logInvitePopupDismissed();
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: Text(l10n.dontShowAgain, style: const TextStyle(color: HushColors.textMuted)),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final box = ctx.findRenderObject() as RenderBox?;
                      final shareOrigin = box != null ? box.localToGlobal(Offset.zero) & box.size : null;
                      if (ctx.mounted) Navigator.pop(ctx);
                      AnalyticsService().logInvitePopupAccepted();
                      AnalyticsService().logShareApp('invite_popup');
                      Future.delayed(const Duration(milliseconds: 300), () {
                        Share.share(l10n.shareAppText, sharePositionOrigin: shareOrigin);
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HushColors.textAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(l10n.inviteFriends, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),'''

new_row = '''              OverflowBar(
                alignment: MainAxisAlignment.spaceBetween,
                overflowAlignment: OverflowBarAlignment.end,
                spacing: 8,
                overflowSpacing: 16,
                children: [
                  TextButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('hasSeenInvitePopup', true);
                      AnalyticsService().logInvitePopupDismissed();
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: Text(l10n.dontShowAgain, style: const TextStyle(color: HushColors.textMuted)),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final box = ctx.findRenderObject() as RenderBox?;
                      final shareOrigin = box != null ? box.localToGlobal(Offset.zero) & box.size : null;
                      if (ctx.mounted) Navigator.pop(ctx);
                      AnalyticsService().logInvitePopupAccepted();
                      AnalyticsService().logShareApp('invite_popup');
                      Future.delayed(const Duration(milliseconds: 300), () {
                        Share.share(l10n.shareAppText, sharePositionOrigin: shareOrigin);
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HushColors.textAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(l10n.inviteFriends, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),'''

content = content.replace(old_row, new_row)

with open('lib/screens/app_shell.dart', 'w', encoding='utf-8') as f:
    f.write(content)
