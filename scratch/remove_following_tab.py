import re

path = 'lib/screens/app_shell.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Remove FollowingScreen from IndexedStack
target1 = '''                CreateScreen(onPublished: () {
                  setState(() => _currentIndex = 0);
                  _feedScreenKey.currentState?.refreshFeed();
                }),
                FollowingScreen(isActive: _currentIndex == 3),
                const ProfileScreen(),'''
replacement1 = '''                CreateScreen(onPublished: () {
                  setState(() => _currentIndex = 0);
                  _feedScreenKey.currentState?.refreshFeed();
                }),
                const ProfileScreen(),'''
content = content.replace(target1, replacement1)

# Remove Following tab from BottomNavigationBar
target2 = '''                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: HushIcon(HushIcons.users, size: 22, color: _currentIndex == 3 ? HushColors.textAccent : HushColors.textSecondary),
                    ),
                    label: l10n.followingTabTitle,
                  ),
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: HushIcon(HushIcons.userCircle, size: 22, color: _currentIndex == 4 ? HushColors.textAccent : HushColors.textSecondary),
                    ),
                    label: l10n.profileTitle,
                  ),'''
replacement2 = '''                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: HushIcon(HushIcons.userCircle, size: 22, color: _currentIndex == 3 ? HushColors.textAccent : HushColors.textSecondary),
                    ),
                    label: l10n.profileTitle,
                  ),'''
content = content.replace(target2, replacement2)

# Update tabNames
target3 = '''                  const tabNames = ['feed', 'map', 'create', 'following', 'profile'];'''
replacement3 = '''                  const tabNames = ['feed', 'map', 'create', 'profile'];'''
content = content.replace(target3, replacement3)

# Update setCurrentTitle
target4 = '''            case 3: title = l10n.followingTabTitle; break;
            case 4: title = l10n.profileTitle; break;'''
replacement4 = '''            case 3: title = l10n.profileTitle; break;'''
content = content.replace(target4, replacement4)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Updated bottom nav in app_shell')
