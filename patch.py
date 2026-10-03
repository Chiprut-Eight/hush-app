import re

with open('lib/screens/admin_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# find children: [\n          _StatCard( ... ]
start_idx = content.find('          children: [\\n          _StatCard(')
end_idx = content.find('        ],\\n      ),\\n      ),\\n    );\\n  }')

if start_idx != -1 and end_idx != -1:
    stat_cards_new = '''          children: [
          _StatCard(
            title: isHe ? 'סך הכל משתמשים רשומים' : 'Total Registered Users',
            subtitle: isHe ? 'ללא אדמין (המשתמש שלך)' : 'Excluding admin',
            value: _totalUsers.toString(),
            icon: Icons.people_alt,
          ),
          const SizedBox(height: 16),
          _StatCard(
            title: isHe ? 'משתמשים חדשים (7 ימים)' : 'New Users (7 Days)',
            subtitle: isHe ? 'הצטרפו בשבוע האחרון' : 'Joined in the last week',
            value: _newUsers7Days.toString(),
            icon: Icons.person_add,
            infoText: isHe ? 'משתמשים חדשים שנוצרו ב-7 הימים האחרונים. מדד לבחינת צמיחת האפליקציה.' : 'Users registered in the last 7 days. Measures app growth.',
          ),
          const SizedBox(height: 16),
          _StatCard(
            title: isHe ? 'משתמשים מחוברים כעת' : 'Users Online Now',
            subtitle: isHe ? 'ללא אדמין (המשתמש שלך)' : 'Excluding admin',
            value: _onlineUsers.toString(),
            icon: Icons.wifi,
          ),
          const SizedBox(height: 32),
          _StatCard(
            title: isHe ? 'סך הכל Hushhh שנוצרו ' : 'Total Secrets Created',
            subtitle: isHe ? 'מאז ומעולם (כולל מחוקים)' : 'All time (including deleted)',
            value: _totalSecretsCreated.toString(),
            icon: Icons.speaker_notes,
            infoText: isHe ? 'הנפח הכולל של הפעילות באפליקציה.' : 'Total volume of activity on the app.',
          ),
          const SizedBox(height: 16),
          _StatCard(
            title: isHe ? 'Hushhh פעילים באוויר' : 'Active Secrets',
            subtitle: isHe ? 'זמינים כרגע במפה/פיד' : 'Currently available on map/feed',
            value: _activeSecrets.toString(),
            icon: Icons.visibility,
          ),
          const SizedBox(height: 16),
          _StatCard(
            title: isHe ? 'Hushhh שנמחקו אוטומטית' : 'Decayed Secrets',
            subtitle: isHe ? 'נמחקו על ידי המערכת עקב חוסר פעילות' : 'Auto-deleted due to inactivity',
            value: _totalSecretsDecayed.toString(),
            icon: Icons.delete_sweep,
            infoText: isHe ? 'מדד לאיכות התוכן. מספר ההאששים שנמחקו כי לא זכו למספיק אינטראקציה מראש.' : 'Measures content quality. Secrets auto-deleted due to low engagement.',
          ),
          const SizedBox(height: 32),
          _StatCard(
            title: isHe ? 'סך הכל דיווחים' : 'Total Reports',
            subtitle: isHe ? 'דיווחים שהוגשו על ידי משתמשים' : 'Reports submitted by users',
            value: _totalReports.toString(),
            icon: Icons.report_problem,
          ),
          const SizedBox(height: 16),
          _StatCard(
            title: isHe ? 'זמן חשיפה ממוצע להאשש' : 'Avg Secret Lifetime',
            subtitle: isHe ? 'זמן מרגע היצירה עד המחיקה' : 'Average time alive',
            value: '\\' h\\'',
            icon: Icons.hourglass_bottom,
            infoText: isHe ? 'הזמן הממוצע (בשעות) שהאשש נמצא באוויר לפני שהוא נמחק ידנית או אוטומטית.' : 'Average time (hours) a secret is live before deletion.',
          ),
          const SizedBox(height: 16),
          _StatCard(
            title: isHe ? 'אחוז השמירות' : 'Saved Percentage',
            subtitle: isHe ? 'מתוך כל ההאששים' : 'Of all secrets',
            value: _savedPercentage,
            icon: Icons.bookmark_border,
            infoText: isHe ? 'אחוז ההאששים שנשמרו על ידי משתמש לפחות פעם אחת מתוך סך ההאששים הקיימים.' : 'Percentage of active secrets that were saved at least once.',
          ),
          const SizedBox(height: 16),
          _StatCard(
            title: isHe ? 'היוצרים המובילים (Top 10)' : 'Top 10 Creators',
            subtitle: isHe ? 'הקלק לצפייה ברשימה המלאה' : 'Tap to view full list',
            value: isHe ? 'הצג רשימה' : 'View List',
            icon: Icons.star_border,
            onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => TopCreatorsScreen(creators: _topCreatorsList, isHe: isHe)));
            },
          ),
          const SizedBox(height: 16),
          _StatCard(
            title: isHe ? 'התפלגות טקסט/קול' : 'Text/Voice Dist.',
            subtitle: isHe ? 'יחס הפורמטים' : 'Format Ratio',
            value: _contentTypeDistribution,
            icon: Icons.pie_chart_outline,
            infoText: isHe ? 'מראה אילו סוגי תוכן מועדפים על המשתמשים באפליקציה.' : 'Shows what content formats users prefer.',
          ),
          const SizedBox(height: 16),
          _StatCard(
            title: isHe ? 'שיעור הדיווחים' : 'Report Rate',
            subtitle: isHe ? 'אחוז מתוך ההאששים המדווחים' : '% of reported secrets',
            value: _reportRate,
            icon: Icons.report_problem_outlined,
            infoText: isHe ? 'כמה אחוז מכלל ההאששים הם האששים שדווחו. עוזר להבין את רמת הבעייתיות של התוכן.' : 'Percentage of active secrets that were reported.',
          ),
          const SizedBox(height: 16),
          _StatCard(
            title: isHe ? 'משתמשים פעילים' : 'Active Users',
            subtitle: isHe ? 'DAU = יומי, WAU = שבועי' : 'Daily / Weekly',
            value: _dauWau,
            icon: Icons.trending_up,
            infoText: isHe ? 'מדד השימור של האפליקציה (Retention).\\nDAU (Daily Active Users) - משתמשים שהיו פעילים ביממה האחרונה.\\nWAU (Weekly Active Users) - משתמשים שהיו פעילים בשבוע האחרון.' : 'User retention metric.\\nDAU = Active in last 24h.\\nWAU = Active in last 7 days.',
          ),
          const SizedBox(height: 16),
          _StatCard(
            title: isHe ? 'ממוצע לייקים/דיסלייקים' : 'Avg Likes/Dislikes',
            subtitle: isHe ? 'להאשש' : 'Per secret',
            value: _avgLikesDislikes,
            icon: Icons.thumbs_up_down,
            infoText: isHe ? 'סנטימנט האפליקציה: האם המשתמשים נוטים יותר לפרגן או להביע חוסר הסכמה.' : 'App sentiment: Do users tend to like or dislike content more?',
          ),'''
    
    new_content = content[:start_idx] + stat_cards_new + content[end_idx:]
    with open('lib/screens/admin_screen.dart', 'w', encoding='utf-8') as f:
        f.write(new_content)
    print("Replaced successfully.")
else:
    print(f"Failed to find indices. start: {start_idx}, end: {end_idx}")
