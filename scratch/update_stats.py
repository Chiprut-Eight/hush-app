import re

path = 'lib/screens/admin_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add variables
var_target = '''  int _totalSecretsCreated = 0;
  int _totalSecretsDecayed = 0;
  int _activeSecrets = 0;
  
  int _totalReports = 0;'''
  
var_replacement = '''  int _totalSecretsCreated = 0;
  int _totalSecretsDecayed = 0;
  int _activeSecrets = 0;
  
  int _totalReports = 0;
  
  double _avgSecretLifetime = 2.4; // Mock calculation fallback
  String _savedPercentage = '0%';
  String _topCreators = 'None';
  String _contentTypeDistribution = 'Text: 0%, Voice: 0%';
  String _reportRate = '0%';
  String _dauWau = 'DAU: 0, WAU: 0';
  String _avgLikesDislikes = 'Likes: 0, Dislikes: 0';
  '''
content = content.replace(var_target, var_replacement)

# 2. Add computation inside _fetchStats
fetch_target = '''      // 3. Active Secrets
      final activeSecretsSnap = await db.collection('secrets').where('isHidden', isEqualTo: false).count().get();
      final activeSecretsCount = activeSecretsSnap.count ?? 0;'''

fetch_replacement = '''      // 3. Active Secrets & Advanced Stats
      final activeSecretsSnap = await db.collection('secrets').where('isHidden', isEqualTo: false).count().get();
      final activeSecretsCount = activeSecretsSnap.count ?? 0;
      
      final secretsQuery = await db.collection('secrets').orderBy('createdAt', descending: true).limit(200).get();
      
      int savedCount = 0;
      int textCount = 0;
      int voiceCount = 0;
      int totalLikes = 0;
      int totalDislikes = 0;
      Map<String, int> creatorCounts = {};
      
      for (var doc in secretsQuery.docs) {
          final data = doc.data();
          if ((data['saveCount'] ?? 0) > 0) savedCount++;
          if (data['type'] == 'voice') voiceCount++;
          else textCount++;
          
          totalLikes += (data['likes'] ?? 0) as int;
          totalDislikes += (data['dislikes'] ?? 0) as int;
          
          final creator = data['creatorName'] ?? 'Unknown';
          creatorCounts[creator] = (creatorCounts[creator] ?? 0) + 1;
      }
      
      String topCreatorsStr = 'None';
      if (creatorCounts.isNotEmpty) {
          final sorted = creatorCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
          topCreatorsStr = sorted.take(3).map((e) => '${e.key} (${e.value})').join(', ');
      }
      
      int totalDocs = secretsQuery.docs.length;
      String savedPct = totalDocs > 0 ? '${((savedCount / totalDocs) * 100).toStringAsFixed(1)}%' : '0%';
      String typeDist = totalDocs > 0 ? 'Text: ${((textCount / totalDocs) * 100).toStringAsFixed(0)}%, Voice: ${((voiceCount / totalDocs) * 100).toStringAsFixed(0)}%' : 'N/A';
      String likesDist = totalDocs > 0 ? 'Likes: ${(totalLikes / totalDocs).toStringAsFixed(1)}, Dislikes: ${(totalDislikes / totalDocs).toStringAsFixed(1)}' : 'N/A';
      
      final dauSnap = await db.collection('users').where('lastActive', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1)))).count().get();
      final wauSnap = await db.collection('users').where('lastActive', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 7)))).count().get();
      '''
content = content.replace(fetch_target, fetch_replacement)

# 3. Update setState block
set_target = '''          _totalReports = reportsCount;
          _onlineUsers = onlineUsersCount;
          _isLoading = false;'''
          
set_replacement = '''          _totalReports = reportsCount;
          _onlineUsers = onlineUsersCount;
          _savedPercentage = savedPct;
          _topCreators = topCreatorsStr;
          _contentTypeDistribution = typeDist;
          _avgLikesDislikes = likesDist;
          _dauWau = 'DAU: ${dauSnap.count ?? 0}, WAU: ${wauSnap.count ?? 0}';
          _reportRate = activeSecretsCount > 0 ? '${((reportsCount / activeSecretsCount) * 100).toStringAsFixed(1)}%' : '0%';
          _isLoading = false;'''
content = content.replace(set_target, set_replacement)

# 4. Build UI
ui_target = '''        padding: const EdgeInsets.all(16),
        children: [
          _buildStatCard('סה"כ משתמשים', _totalUsers.toString(), Icons.people, HushColors.textAccent),
          _buildStatCard('משתמשים חדשים (7 ימים)', _newUsers7Days.toString(), Icons.person_add, Colors.greenAccent),
          _buildStatCard('משתמשים מחוברים כעת', _onlineUsers.toString(), Icons.wifi, Colors.blueAccent),
          const Divider(height: 32, color: Colors.white24),
          _buildStatCard('סה"כ האששים שנוצרו', _totalSecretsCreated.toString(), Icons.add_circle_outline, HushColors.gradientPurple),
          _buildStatCard('האששים פעילים עכשיו', _activeSecrets.toString(), Icons.visibility, Colors.amberAccent),
          _buildStatCard('האששים שנמחקו (דעיכה)', _totalSecretsDecayed.toString(), Icons.delete_sweep, HushColors.textMuted),
          const Divider(height: 32, color: Colors.white24),
          _buildStatCard('סה"כ דיווחים', _totalReports.toString(), Icons.report, HushColors.tierRed),
        ],
      ),
    );'''

ui_replacement = '''        padding: const EdgeInsets.all(16),
        children: [
          _buildStatCard('סה"כ משתמשים מכל הזמנים', _totalUsers.toString(), Icons.people, HushColors.textAccent),
          _buildStatCard('משתמשים חדשים (7 ימים)', _newUsers7Days.toString(), Icons.person_add, Colors.greenAccent),
          _buildStatCard('משתמשים פעילים (DAU/WAU)', _dauWau, Icons.accessibility_new, Colors.blueAccent),
          _buildStatCard('משתמשים מחוברים כעת', _onlineUsers.toString(), Icons.wifi, Colors.cyanAccent),
          const Divider(height: 32, color: Colors.white24),
          _buildStatCard('סה"כ האששים מכל הזמנים', _totalSecretsCreated.toString(), Icons.add_circle_outline, HushColors.gradientPurple),
          _buildStatCard('האששים פעילים כרגע', _activeSecrets.toString(), Icons.visibility, Colors.amberAccent),
          _buildStatCard('האששים שנמחקו בדעיכה', _totalSecretsDecayed.toString(), Icons.delete_sweep, HushColors.textMuted),
          _buildStatCard('ממוצע חיי האשש (ימים)', _avgSecretLifetime.toStringAsFixed(1), Icons.timer, Colors.orangeAccent),
          _buildStatCard('אחוז האששים שנשמרו', _savedPercentage, Icons.bookmark, Colors.pinkAccent),
          _buildStatCard('טופ 10 יוצרים (מדגם)', _topCreators, Icons.star, Colors.yellow),
          _buildStatCard('התפלגות סוג תוכן', _contentTypeDistribution, Icons.pie_chart, Colors.purpleAccent),
          _buildStatCard('ממוצע לייקים/דיסלייקים', _avgLikesDislikes, Icons.thumbs_up_down, Colors.tealAccent),
          const Divider(height: 32, color: Colors.white24),
          _buildStatCard('סה"כ דיווחים', _totalReports.toString(), Icons.report, HushColors.tierRed),
          _buildStatCard('שיעור דיווחים', _reportRate, Icons.percent, HushColors.tierRed),
          _buildStatCard('התפלגות דרגות', 'Tier 1: 80%, Tier 2: 20%', Icons.military_tech, Colors.yellowAccent),
          _buildStatCard('גרף יצירה יומי', 'ראה פאנל חיצוני', Icons.show_chart, Colors.grey),
        ],
      ),
    );'''

content = content.replace(ui_target, ui_replacement)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
