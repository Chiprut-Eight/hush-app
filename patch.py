import re

with open('lib/screens/app_shell.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add _switchTab method
method = '''
  void _switchTab(int index) {
    if (_currentIndex != index) {
      HapticFeedback.lightImpact();
    }
    setState(() => _currentIndex = index);
    
    final localL10n = AppLocalizations.of(context)!;
    String newTitle = '';
    switch (index) {
      case 0:
        newTitle = _feedScreenKey.currentState?.getCurrentTitle(context) ?? localL10n.feedTitle;
        break;
      case 1: newTitle = localL10n.mapTitle; break;
      case 2: newTitle = localL10n.createTitle; break;
      case 3: newTitle = localL10n.followingTabTitle; break;
      case 4: newTitle = localL10n.profileTitle; break;
    }
    context.read<UIProvider>().setCurrentTitle(newTitle);
    
    const tabNames = ['feed', 'map', 'create', 'following', 'profile'];
    AnalyticsService().logTabChanged(tabNames[index]);
  }
'''

content = content.replace("class _AppShellState extends State<AppShell> {", "class _AppShellState extends State<AppShell> {" + method)

# Replace PopScope logic
pop_scope_old = '''            // 2. If not on the first tab, go back to it
            if (_currentIndex != 0) {
              setState(() => _currentIndex = 0);
              return;
            }'''
            
pop_scope_new = '''            // 2. If not on the first tab, go back to it
            if (_currentIndex != 0) {
              _switchTab(0);
              return;
            }'''
            
content = content.replace(pop_scope_old, pop_scope_new)

# Replace CreateScreen callback
create_callback_old = '''                CreateScreen(onPublished: () {
                  setState(() => _currentIndex = 0);
                  _feedScreenKey.currentState?.refreshFeed();
                }),'''
                
create_callback_new = '''                CreateScreen(onPublished: () {
                  _switchTab(0);
                  _feedScreenKey.currentState?.refreshFeed();
                }),'''
                
content = content.replace(create_callback_old, create_callback_new)

# Replace onTap in BottomNavigationBar
on_tap_old = '''                onTap: (index) {
                  if (_currentIndex != index) {
                    HapticFeedback.lightImpact();
                  }
                  setState(() => _currentIndex = index);
                  
                  final localL10n = AppLocalizations.of(context)!;
                  String newTitle = '';
                  switch (index) {
                    case 0:
                      newTitle = _feedScreenKey.currentState?.getCurrentTitle(context) ?? localL10n.feedTitle;
                      break;
                    case 1: newTitle = localL10n.mapTitle; break;
                    case 2: newTitle = localL10n.createTitle; break;
                    case 3: newTitle = localL10n.followingTabTitle; break;
                    case 4: newTitle = localL10n.profileTitle; break;
                  }
                  context.read<UIProvider>().setCurrentTitle(newTitle);
                  
                  const tabNames = ['feed', 'map', 'create', 'following', 'profile'];
                  AnalyticsService().logTabChanged(tabNames[index]);
                },'''
                
on_tap_new = '''                onTap: _switchTab,'''

content = content.replace(on_tap_old, on_tap_new)

with open('lib/screens/app_shell.dart', 'w', encoding='utf-8') as f:
    f.write(content)
