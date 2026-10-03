import re

with open('lib/screens/app_shell.dart', 'r', encoding='utf-8') as f:
    content = f.read()

init_state_old = '''  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _lastTier = null;
  }'''
  
init_state_new = '''  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _lastTier = null;
    
    // Set initial title after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _switchTab(_currentIndex);
    });
  }'''

content = content.replace(init_state_old, init_state_new)

with open('lib/screens/app_shell.dart', 'w', encoding='utf-8') as f:
    f.write(content)
