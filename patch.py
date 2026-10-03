import re

with open('lib/screens/feed_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

get_title = '''
  String getCurrentTitle(BuildContext context) {
    final isHe = Localizations.localeOf(context).languageCode == 'he';
    if (_selectedTab == FeedTab.nearby) {
      return isHe ? 'Hushhh בקרבתך' : 'Hushhh Nearby';
    } else if (_selectedTab == FeedTab.following) {
      return isHe ? 'Hushhh במעקב' : 'Hushhh Following';
    } else if (_selectedTab == FeedTab.saved) {
      return isHe ? 'Hushhh שמורים' : 'Hushhh Saved';
    }
    return '';
  }

  void _updateAppBarTitle() {'''

content = content.replace("  void _updateAppBarTitle() {", get_title)

with open('lib/screens/feed_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
