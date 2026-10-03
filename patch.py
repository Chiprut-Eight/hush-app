import re

with open('lib/screens/feed_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Remove _updateAppBarTitle() from build
content = content.replace("  @override\n  Widget build(BuildContext context) {\n    _updateAppBarTitle();", "  @override\n  Widget build(BuildContext context) {\n")

# Call _updateAppBarTitle in onTap
old_ontap = '''        onTap: () {
          if (_selectedTab == tab) return;
          setState(() {
            _selectedTab = tab;
            _isLoading = true;
          });
          _fetchSecrets();
        },'''
        
new_ontap = '''        onTap: () {
          if (_selectedTab == tab) return;
          setState(() {
            _selectedTab = tab;
            _isLoading = true;
          });
          
          // Update title only if this screen is currently active
          // If another tab in bottom bar is active, AppShell handles its title
          final isHe = Localizations.localeOf(context).languageCode == 'he';
          String title = '';
          if (tab == FeedTab.nearby) {
            title = isHe ? 'Hushhh בקרבתך' : 'Hushhh Nearby';
          } else if (tab == FeedTab.following) {
            title = isHe ? 'Hushhh במעקב' : 'Hushhh Following';
          } else if (tab == FeedTab.saved) {
            title = isHe ? 'Hushhh שמורים' : 'Hushhh Saved';
          }
          context.read<UIProvider>().setCurrentTitle(title);
          
          _fetchSecrets();
        },'''

content = content.replace(old_ontap, new_ontap)

with open('lib/screens/feed_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
