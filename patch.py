import re

with open('lib/screens/feed_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace padding: const EdgeInsets.symmetric(vertical: 12)
content = re.sub(r'padding: const EdgeInsets\.symmetric\(vertical: 12\),', 'padding: const EdgeInsets.symmetric(vertical: 6),', content)

# Replace SizedBox(width: 24)
content = re.sub(r'const SizedBox\(width: 24\),', 'const SizedBox(width: 12),', content)

# Replace fontSize: 16
content = re.sub(r'fontSize: 16,', 'fontSize: 14,', content)

# Replace margin: const EdgeInsets.only(top: 4)
content = re.sub(r'margin: const EdgeInsets\.only\(top: 4\),', 'margin: const EdgeInsets.only(top: 2),', content)

with open('lib/screens/feed_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
