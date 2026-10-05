import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hush_app/config/theme.dart';
import 'package:hush_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/ui_provider.dart';
import '../core/constants/icons.dart';
import '../widgets/hush_icon_widget.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/analytics_service.dart';
import 'create_screen.dart';
import 'package:just_audio/just_audio.dart';
import '../widgets/title_setter.dart';
import 'package:firebase_database/firebase_database.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  @override
  void initState() {
    super.initState();
    _ensureAdminFlag();
  }

  void _ensureAdminFlag() {
    final user = Provider.of<AuthProvider>(context, listen: false).firebaseUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'isAdmin': true})
          .catchError((_) {});

      // Grant screenshot permission to tester yakir sabag
      FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: 'yakeer@gmail.com')
          .limit(1)
          .get()
          .then((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          snapshot.docs.first.reference.update({'canScreenshot': true}).catchError((_) {});
        }
      }).catchError((_) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isHe = Localizations.localeOf(context).languageCode == 'he';

    return TitleSetter(
      title: l10n.adminTitle,
      child: Scaffold(
        backgroundColor: HushColors.bgPrimary,
        appBar: AppBar(
          title: Text(l10n.adminTitle),
          centerTitle: true,
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildAdminButton(
              context,
              icon: Icons.notifications_active,
              label: isHe ? 'הודעות פוש לכולם' : 'Global Push',
              color: HushColors.gradientPurple,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _PushNotificationScreen())),
            ),
            const SizedBox(height: 16),
            _buildAdminButton(
              context,
              icon: Icons.report_problem,
              label: isHe ? 'דיווחים וערעורים' : 'Reports & Appeals',
              color: HushColors.tierRed,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _ReportsAppealsScreen())),
            ),
            const SizedBox(height: 16),
            _buildAdminButton(
              context,
              icon: Icons.build_circle,
              label: l10n.maintenanceTitle,
              color: HushColors.textAccent,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _MaintenanceScreen())),
            ),
            const SizedBox(height: 16),
            _buildAdminButton(
              context,
              icon: Icons.bar_chart,
              label: isHe ? 'סטטיסטיקות' : 'Statistics',
              color: Colors.amber.shade700,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _StatisticsScreen())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminButton(BuildContext context, {required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: HushColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

class _ReportsAppealsScreen extends StatelessWidget {
  const _ReportsAppealsScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isHe = Localizations.localeOf(context).languageCode == 'he';
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isHe ? 'דיווחים וערעורים' : 'Reports & Appeals'),
          bottom: TabBar(
            indicatorColor: HushColors.textAccent,
            tabs: [
              Tab(text: l10n.reports),
              Tab(text: l10n.appeals),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ReportsList(),
            _AppealsList(),
          ],
        ),
      ),
    );
  }
}

class _PushNotificationScreen extends StatelessWidget {
  const _PushNotificationScreen();

  @override
  Widget build(BuildContext context) {
    final isHe = Localizations.localeOf(context).languageCode == 'he';
    return Scaffold(
      appBar: AppBar(title: Text(isHe ? 'הודעות פוש לכלל המשתמשים' : 'Global Push Notifications')),
      body: const _PushNotificationView(),
    );
  }
}

class _StatisticsScreen extends StatelessWidget {
  const _StatisticsScreen();

  @override
  Widget build(BuildContext context) {
    final isHe = Localizations.localeOf(context).languageCode == 'he';
    return Scaffold(
      backgroundColor: HushColors.bgPrimary,
      appBar: AppBar(
        title: Text(isHe ? 'סטטיסטיקות מנהל' : 'Admin Statistics'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
      ),
      body: const _StatisticsView(),
    );
  }
}

// ============================================================================
// 1. APPEALS LIST
// ============================================================================
class _AppealsList extends StatelessWidget {
  const _AppealsList();

  Future<void> _handleDecision(
    BuildContext context,
    DocumentReference appealRef,
    String userId,
    String userName,
    bool approve,
  ) async {
    final isHe = Localizations.localeOf(context).languageCode == 'he';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: HushColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          approve
              ? (isHe ? 'אישור ערעור ובטל עונש' : 'Approve Appeal & Lift Ban')
              : (isHe ? 'דחיית ערעור' : 'Reject Appeal'),
          style: TextStyle(
            color: approve ? HushColors.textAccent : HushColors.tierRed,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          approve
              ? (isHe
                  ? 'האם לבטל את מצב הרפאים עבור $userName ולאפס את מונה הדיווחים שלו?'
                  : 'Lift Ghost Mode for $userName and reset report count?')
              : (isHe
                  ? 'האם לדחות את הערעור? המשתמש יישאר במצב רפאים עד לתום התקופה.'
                  : 'Reject appeal? The user will remain in Ghost Mode until expiration.'),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isHe ? 'ביטול' : 'Cancel', style: const TextStyle(color: HushColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: approve ? HushColors.textAccent : HushColors.tierRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              approve ? (isHe ? 'אשר ובטל עונש' : 'Approve') : (isHe ? 'דחה ערעור' : 'Reject'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // 1. Update the appeal status
    await appealRef.update({'status': approve ? 'approved' : 'rejected'});

    // 2. If approved, lift Ghost Mode directly in the users collection
    if (approve && userId.isNotEmpty) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isGhostMode': false,
        'ghostModeUntil': FieldValue.delete(),
        'reportsCount': 0,
      });

      // Send notification to user
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'title': {
          'en': '✅ Appeal Approved',
          'he': '✅ הערעור שלך אושר',
        },
        'body': {
          'en': 'Your appeal was approved! Ghost Mode has been lifted from your account.',
          'he': 'הערעור שלך התקבל! מצב רפאים בוטל וחשבונך חזר לפעילות מלאה.',
        },
        'data': {'type': 'appeal_result'},
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      AnalyticsService().logAdminAppealDecision(appealId: appealRef.id, approved: true);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isHe ? 'הערעור אושר והעונש בוטל בהצלחה!' : 'Appeal approved & ban lifted!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else if (userId.isNotEmpty) {
      // Send notification to user
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'title': {
          'en': '❌ Appeal Rejected',
          'he': '❌ הערעור נדחה',
        },
        'body': {
          'en': 'Your appeal was reviewed and rejected. Your account will remain in Ghost Mode.',
          'he': 'הערעור שלך נבדק ונדחה. חשבונך יישאר במצב רפאים עד לתום התקופה.',
        },
        'data': {'type': 'appeal_result'},
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      AnalyticsService().logAdminAppealDecision(appealId: appealRef.id, approved: false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isHe ? 'הערעור נדחה.' : 'Appeal rejected.'),
            backgroundColor: HushColors.tierRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isHe = Localizations.localeOf(context).languageCode == 'he';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appeals')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: HushColors.tierRed)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('✅', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(l10n.noAppeals, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs.toList();
        docs.sort((a, b) {
          final da = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          final db = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          final ta = da?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
          final tb = db?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
          return tb.compareTo(ta);
        });

        return ListView(
          padding: const EdgeInsets.all(16),
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final date = (data['createdAt'] as Timestamp?)?.toDate();
            final userId = data['userId'] ?? '';

            return FutureBuilder<DocumentSnapshot>(
              future: userId.isNotEmpty
                  ? FirebaseFirestore.instance.collection('users').doc(userId).get()
                  : null,
              builder: (context, userSnap) {
                final uData = userSnap.data?.data() as Map<String, dynamic>?;
                final email = data['userEmail'] ?? uData?['email'] ?? (isHe ? 'ללא אימייל' : 'No Email');
                final firstName = uData?['firstName'] as String? ?? '';
                final lastName = uData?['lastName'] as String? ?? '';
                final fullName = '$firstName $lastName'.trim();
                final displayName = fullName.isNotEmpty
                    ? fullName
                    : (uData?['displayName'] ?? data['userName'] ?? (isHe ? 'משתמש' : 'User'));

                return Card(
                  color: HushColors.bgCard,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (date != null)
                              Text(
                                '${date.day}/${date.month}/${date.year}',
                                style: const TextStyle(color: HushColors.textSecondary, fontSize: 12),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${isHe ? 'אימייל:' : 'Email:'} $email',
                          style: const TextStyle(color: HushColors.textAccent, fontSize: 13),
                        ),
                        Text(
                          '${isHe ? 'מזהה משתמש:' : 'UID:'} $userId',
                          style: const TextStyle(color: HushColors.textMuted, fontSize: 11),
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: Colors.white12),
                        const SizedBox(height: 8),
                        Text(
                          isHe ? 'נימוק הערעור:' : 'Appeal Reason:',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            data['reason'] ?? (isHe ? 'לא צוין נימוק.' : 'No reason provided.'),
                            style: const TextStyle(color: Colors.white70, height: 1.4),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _handleDecision(context, doc.reference, userId, displayName, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: HushColors.textAccent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    isHe ? 'אשר ובטל עונש' : 'Approve & Unban',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _handleDecision(context, doc.reference, userId, displayName, false),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: HushColors.tierRed),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    isHe ? 'דחה ערעור' : 'Reject',
                                    style: const TextStyle(color: HushColors.tierRed, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }
}

// ============================================================================
// 2. REPORTS LIST & REPORT ITEM
// ============================================================================
class _ReportsList extends StatelessWidget {
  const _ReportsList();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reports')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: HushColors.tierRed)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('✅', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(l10n.noReports, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs.toList();
        docs.sort((a, b) {
          final da = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          final db = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          final ta = da?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
          final tb = db?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
          return tb.compareTo(ta);
        });

        return ListView(
          padding: const EdgeInsets.all(16),
          children: docs.map((doc) => _ReportCardItem(reportDoc: doc)).toList(),
        );
      },
    );
  }
}

/// A comprehensive data bundle for a report item
class _ReportBundle {
  final Map<String, dynamic> reportData;
  final Map<String, dynamic>? secretData;
  final Map<String, dynamic>? contentData;
  final Map<String, dynamic>? creatorData;
  final Map<String, dynamic>? reporterData;

  const _ReportBundle({
    required this.reportData,
    this.secretData,
    this.contentData,
    this.creatorData,
    this.reporterData,
  });
}

class _ReportCardItem extends StatelessWidget {
  final DocumentSnapshot reportDoc;

  const _ReportCardItem({required this.reportDoc});

  Future<_ReportBundle> _loadBundle() async {
    final reportData = reportDoc.data() as Map<String, dynamic>;
    final secretId = reportData['secretId'] as String? ?? '';
    final reporterId = reportData['reporterId'] as String? ?? '';
    String? creatorId = reportData['creatorId'] as String?;

    Map<String, dynamic>? secretData;
    Map<String, dynamic>? contentData;
    Map<String, dynamic>? creatorData;
    Map<String, dynamic>? reporterData;

    // 1. Fetch secret
    if (secretId.isNotEmpty) {
      try {
        final sSnap = await FirebaseFirestore.instance.collection('secrets').doc(secretId).get();
        if (sSnap.exists) {
          secretData = sSnap.data();
          creatorId ??= secretData?['creatorId'] as String?;
        }
      } catch (_) {}

      // 2. Fetch secret content subcollection
      try {
        final cSnap = await FirebaseFirestore.instance
            .collection('secrets')
            .doc(secretId)
            .collection('content')
            .doc('data')
            .get();
        if (cSnap.exists) {
          contentData = cSnap.data();
        }
      } catch (_) {}
    }

    // 3. Fetch creator profile
    if (creatorId != null && creatorId.isNotEmpty) {
      try {
        final uSnap = await FirebaseFirestore.instance.collection('users').doc(creatorId).get();
        if (uSnap.exists) {
          creatorData = uSnap.data();
        }
      } catch (_) {}
    }

    // 4. Fetch reporter profile
    if (reporterId.isNotEmpty) {
      try {
        final rSnap = await FirebaseFirestore.instance.collection('users').doc(reporterId).get();
        if (rSnap.exists) {
          reporterData = rSnap.data();
        }
      } catch (_) {}
    }

    return _ReportBundle(
      reportData: reportData,
      secretData: secretData,
      contentData: contentData,
      creatorData: creatorData,
      reporterData: reporterData,
    );
  }

  /// Show duration dialog and punish the CREATOR of the secret
  Future<void> _handleDeleteAndPunish(
    BuildContext context,
    String secretId,
    String? creatorId,
    String creatorName,
    String creatorEmail,
    String reporterName,
    {String? commentId}
  ) async {
    final isHe = Localizations.localeOf(context).languageCode == 'he';

    if (creatorId == null || creatorId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isHe
              ? 'שגיאה: לא נמצא מזהה יוצר להעברה למצב רפאים.'
              : 'Error: Creator ID not found.'),
          backgroundColor: HushColors.tierRed,
        ),
      );
      return;
    }

    final isComment = commentId != null && commentId.isNotEmpty;

    // Show duration picker modal
    final duration = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: HushColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isHe 
              ? (isComment ? '🗑️ מחיקת תגובה וענישת יוצר' : '🗑️ מחיקת האשש וענישת יוצר')
              : (isComment ? '🗑️ Delete Comment & Punish Creator' : '🗑️ Delete Secret & Punish Creator'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: HushColors.tierRed.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: HushColors.tierRed.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isHe
                        ? (isComment ? 'פעולה זו תמחק לצמיתות את התגובה ותעביר את היוצר למצב רפאים:' : 'פעולה זו תמחק לצמיתות את ההאשש ותעביר את היוצר למצב רפאים:')
                        : (isComment ? 'This will permanently delete the comment and put the creator in Ghost Mode:' : 'This will permanently delete the secret and put the creator in Ghost Mode:'),
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '👤 ${isHe ? 'יוצר (נענש):' : 'Creator (punished):'} $creatorName',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  if (creatorEmail.isNotEmpty)
                    Text(
                      '📧 $creatorEmail',
                      style: const TextStyle(color: HushColors.textAccent, fontSize: 12),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '📣 ${isHe ? 'המדווח (לא ייפגע):' : 'Reporter (safe):'} $reporterName',
                    style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isHe
                  ? 'בחר לכמה זמן להעביר את היוצר למצב רפאים:'
                  : 'Select Ghost Mode duration for the creator:',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            ...[
              {'labelHe': '24 שעות', 'labelEn': '24 Hours', 'hours': 24},
              {'labelHe': '48 שעות', 'labelEn': '48 Hours', 'hours': 48},
              {'labelHe': '7 ימים (שבוע)', 'labelEn': '7 Days', 'hours': 168},
              {'labelHe': '14 ימים (שבועיים)', 'labelEn': '14 Days', 'hours': 336},
              {'labelHe': '21 ימים (3 שבועות)', 'labelEn': '21 Days', 'hours': 504},
              {'labelHe': '30 ימים (חודש)', 'labelEn': '30 Days', 'hours': 720},
            ].map((opt) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, opt['hours'] as int),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HushColors.tierRed.withValues(alpha: 0.25),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(isHe ? (opt['labelHe'] as String) : (opt['labelEn'] as String)),
                ),
              ),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text(isHe ? 'ביטול' : 'Cancel', style: const TextStyle(color: HushColors.textMuted)),
          ),
        ],
      ),
    );

    if (duration == null) return; // Cancelled

    // 1. Mark report as actioned
    await reportDoc.reference.update({'status': 'actioned'});

    // 2. Delete secret or comment
    if (secretId.isNotEmpty) {
      if (isComment) {
        try {
          await FirebaseFirestore.instance
              .collection('secrets')
              .doc(secretId)
              .collection('comments')
              .doc(commentId)
              .delete();
          AnalyticsService().logAdminReportDecision(reportId: reportDoc.id, secretId: secretId, deleted: true);
        } catch (_) {}
      } else {
        try {
          await FirebaseFirestore.instance
              .collection('secrets')
              .doc(secretId)
              .collection('content')
              .doc('data')
              .delete();
        } catch (_) {}
        await FirebaseFirestore.instance.collection('secrets').doc(secretId).delete();
        AnalyticsService().logAdminReportDecision(reportId: reportDoc.id, secretId: secretId, deleted: true);
      }
    }

    // 3. Put ONLY the creator into Ghost Mode
    final ghostUntil = DateTime.now().add(Duration(hours: duration));
    await FirebaseFirestore.instance.collection('users').doc(creatorId).update({
      'isGhostMode': true,
      'ghostModeUntil': Timestamp.fromDate(ghostUntil),
    });

    // 4. Build duration label
    String durationLabelEn;
    String durationLabelHe;
    if (duration <= 48) {
      durationLabelEn = '$duration hours';
      durationLabelHe = '$duration שעות';
    } else {
      final days = duration ~/ 24;
      durationLabelEn = '$days days';
      durationLabelHe = '$days ימים';
    }

    // 5. Save notification to the punished creator's history
    await FirebaseFirestore.instance
        .collection('users')
        .doc(creatorId)
        .collection('notifications')
        .add({
      'title': {
        'en': '⚠️ Ghost Mode Activated',
        'he': '⚠️ מצב רפאים הופעל',
      },
      'body': {
        'en': 'Your account has been placed in Ghost Mode for $durationLabelEn due to a content violation.',
        'he': 'החשבון שלך הועבר למצב רפאים למשך $durationLabelHe עקב הפרת תוכן.',
      },
      'data': {'type': 'ghost_mode'},
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isHe
                ? 'ההאשש נמחק והיוצר $creatorName הועבר למצב רפאים למשך $durationLabelHe!'
                : 'Secret deleted and $creatorName placed in Ghost Mode for $durationLabelEn!',
          ),
          backgroundColor: HushColors.tierRed,
        ),
      );
    }
  }

  /// Dismiss report without punishment
  Future<void> _handleDismiss(BuildContext context, String secretId) async {
    final isHe = Localizations.localeOf(context).languageCode == 'he';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: HushColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isHe ? 'סגירת דיווח' : 'Dismiss Report',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          isHe
              ? 'האם לסגור דיווח זה ללא ענישה? ההאשש יישאר פעיל והיוצר לא ייענש.'
              : 'Dismiss this report? The secret will remain active and the creator will not be punished.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isHe ? 'ביטול' : 'Cancel', style: const TextStyle(color: HushColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white24,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(isHe ? 'סגור דיווח' : 'Dismiss', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await reportDoc.reference.update({'status': 'dismissed'});
    if (secretId.isNotEmpty) {
      AnalyticsService().logAdminReportDecision(reportId: reportDoc.id, secretId: secretId, deleted: false);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isHe ? 'הדיווח נסגר ללא ענישה.' : 'Report dismissed.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHe = Localizations.localeOf(context).languageCode == 'he';

    return FutureBuilder<_ReportBundle>(
      future: _loadBundle(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            color: HushColors.bgCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.only(bottom: 16),
            child: const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          );
        }

        final bundle = snapshot.data;
        final reportData = bundle?.reportData ?? (reportDoc.data() as Map<String, dynamic>);
        final secretData = bundle?.secretData;
        final contentData = bundle?.contentData;
        final creatorData = bundle?.creatorData;
        final reporterData = bundle?.reporterData;

        final date = (reportData['createdAt'] as Timestamp?)?.toDate();
        final secretId = reportData['secretId'] as String? ?? '';
        final commentId = reportData['commentId'] as String?;

        // Resolved Creator Info
        final creatorId = reportData['creatorId'] as String? ?? secretData?['creatorId'] as String? ?? '';
        final creatorFirstName = creatorData?['firstName'] as String? ?? '';
        final creatorLastName = creatorData?['lastName'] as String? ?? '';
        final creatorFullName = '$creatorFirstName $creatorLastName'.trim();
        final creatorDisplayName = creatorFullName.isNotEmpty
            ? creatorFullName
            : (creatorData?['displayName'] ?? reportData['creatorName'] ?? secretData?['creatorName'] ?? (isHe ? 'יוצר אנונימי' : 'Anonymous Creator'));
        final creatorEmail = creatorData?['email'] as String? ?? '';
        final creatorIsGhost = creatorData?['isGhostMode'] == true;

        // Resolved Reporter Info
        final reporterId = reportData['reporterId'] as String? ?? '';
        final reporterFirstName = reporterData?['firstName'] as String? ?? '';
        final reporterLastName = reporterData?['lastName'] as String? ?? '';
        final reporterFullName = '$reporterFirstName $reporterLastName'.trim();
        final reporterDisplayName = reporterFullName.isNotEmpty
            ? reporterFullName
            : (reporterData?['displayName'] ?? reportData['reporterName'] ?? (isHe ? 'מדווח אנונימי' : 'Anonymous Reporter'));
        final reporterEmail = (reportData['reporterEmail'] != null && (reportData['reporterEmail'] as String).isNotEmpty)
            ? reportData['reporterEmail'] as String
            : (reporterData?['email'] as String? ?? (isHe ? 'לא צוין אימייל' : 'No email'));

        // Resolved Content
        final reportedText = contentData?['textContent'] as String? ?? secretData?['textContent'] as String? ?? reportData['reportedContent'] as String? ?? '';
        final secretType = secretData?['type'] as String? ?? reportData['secretType'] as String? ?? 'text';
        final isVoice = secretType == 'voice';
        final isSecretDeleted = secretData == null && contentData == null && reportedText.isEmpty;

        return Card(
          color: HushColors.bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: Title + Date
                Row(
                  children: [
                    const Icon(Icons.report_problem, color: HushColors.tierRed, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isHe ? 'דיווח על האשש' : 'Reported Secret',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    if (date != null)
                      Text(
                        '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: HushColors.textSecondary, fontSize: 11),
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                // ==========================================
                // SECTION 1: REPORTED CREATOR (נענש פוטנציאלי)
                // ==========================================
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isHe ? '👤 יוצר ההאשש (המשתמש שדווח):' : '👤 Secret Creator (Reported User):',
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: creatorIsGhost
                                  ? HushColors.tierRed.withValues(alpha: 0.2)
                                  : Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              creatorIsGhost
                                  ? (isHe ? '👻 במצב רפאים' : '👻 In Ghost Mode')
                                  : (isHe ? '✅ פעיל' : '✅ Active'),
                              style: TextStyle(
                                color: creatorIsGhost ? HushColors.tierRed : Colors.greenAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${isHe ? 'שם היוצר:' : 'Name:'} $creatorDisplayName',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      if (creatorEmail.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${isHe ? 'אימייל:' : 'Email:'} $creatorEmail',
                          style: const TextStyle(color: HushColors.textAccent, fontSize: 12),
                        ),
                        if (creatorEmail.endsWith('@privaterelay.appleid.com'))
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              children: [
                                const Icon(Icons.shield_outlined, size: 12, color: Colors.white54),
                                const SizedBox(width: 4),
                                Text(
                                  isHe ? 'ממסר פרטי של Apple (הסתרת דוא״ל)' : 'Apple Private Relay (Hidden Email)',
                                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                      ],
                      if (creatorId.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${isHe ? 'מזהה יוצר (UID):' : 'Creator UID:'} $creatorId',
                          style: const TextStyle(color: HushColors.textMuted, fontSize: 10),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ==========================================
                // SECTION 2: REPORTED SECRET CONTENT
                // ==========================================
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isHe ? '💬 תוכן ההאשש:' : '💬 Secret Content:',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ID: $secretId',
                            style: const TextStyle(color: HushColors.textMuted, fontSize: 10),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (isSecretDeleted) ...[
                        Text(
                          isHe ? 'ההאשש כבר נמחק או אינו קיים במערכת' : 'Secret has already been deleted or missing.',
                          style: const TextStyle(color: HushColors.textMuted, fontSize: 13, fontStyle: FontStyle.italic),
                        ),
                      ] else if (isVoice) ...[
                        _AdminAudioPlayer(
                          audioURL: secretData?['audioURL'] as String? ?? contentData?['audioURL'] as String?,
                          isHe: isHe,
                        ),
                      ] else ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            reportedText.isNotEmpty
                                ? reportedText
                                : (isHe ? '(תוכן טקסטואלי ריק)' : '(Empty text content)'),
                            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.3),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ==========================================
                // SECTION 3: REPORTER INFO (מי שדיווח)
                // ==========================================
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isHe ? '📣 פרטי המדווח:' : '📣 Reporter Details:',
                              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (reportData['reportCount'] != null && reportData['reportCount'] > 1)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: HushColors.tierRed.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isHe ? '${reportData['reportCount']} דיווחים' : '${reportData['reportCount']} Reports',
                                style: const TextStyle(color: HushColors.tierRed, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${isHe ? 'מדווח על ידי:' : 'Reported by:'} ${(reportData['reporterNames'] as List<dynamic>?)?.join(', ') ?? reporterDisplayName}',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${isHe ? 'אימייל מדווח:' : 'Reporter email:'} $reporterEmail',
                        style: const TextStyle(color: HushColors.textAccent, fontSize: 12),
                      ),
                      if (reporterEmail.endsWith('@privaterelay.appleid.com'))
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              const Icon(Icons.shield_outlined, size: 12, color: Colors.white54),
                              const SizedBox(width: 4),
                              Text(
                                isHe ? 'ממסר פרטי של Apple (הסתרת דוא״ל)' : 'Apple Private Relay (Hidden Email)',
                                style: const TextStyle(color: Colors.white54, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      Text(
                        '${isHe ? 'מזהה מדווח:' : 'Reporter ID:'} $reporterId',
                        style: const TextStyle(color: HushColors.textMuted, fontSize: 10),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${isHe ? 'עילת הדיווח:' : 'Reason:'} ${reportData['reason'] ?? (isHe ? 'לא צוינה סיבה' : 'Not specified')}',
                        style: const TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // ==========================================
                // SECTION 4: ACTIONS
                // ==========================================
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: ElevatedButton(
                        onPressed: () => _handleDeleteAndPunish(
                          context,
                          secretId,
                          creatorId,
                          creatorDisplayName,
                          creatorEmail,
                          reporterDisplayName,
                          commentId: commentId,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HushColors.tierRed,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.delete_forever, size: 16, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                isHe ? 'מחק והעבר למצב רפאים' : 'Delete & Ghost',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 4,
                      child: OutlinedButton(
                        onPressed: () => _handleDismiss(context, secretId),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            isHe ? 'התעלם מדיווח' : 'Dismiss',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// 3. MAINTENANCE VIEW
// ============================================================================
class _MaintenanceScreen extends StatelessWidget {
  const _MaintenanceScreen();

  Future<void> _sendTestNotification(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final isHe = Localizations.localeOf(context).languageCode == 'he';
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'hush_custom_notifications',
      'Hushhh Notifications',
      channelDescription: 'Notifications from the Hushhh app',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('shush_push'),
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'shush_push.wav',
      ),
    );

    await flutterLocalNotificationsPlugin.show(
      888,
      isHe ? 'בדיקת התראה מקומית' : 'Local Test Notification',
      isHe ? 'ההתראות המקומיות פועלות כשורה באפליקציה!' : 'Local notifications are functioning properly!',
      platformChannelSpecifics,
    );

    if (context.mounted) {
      AnalyticsService().logAdminMaintenanceAction('test_push_notification');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.testPushSuccess)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isHe = Localizations.localeOf(context).languageCode == 'he';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.maintenanceTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          Text(
            isHe ? '🛠️ כלי תחזוקה ובדיקות' : '🛠️ Maintenance & Testing Tools',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildMaintenanceButton(
            context,
            icon: Icons.palette,
            label: isHe ? 'תצוגה מקדימה של צבעי דרגות' : 'Tier Colors Preview',
            color: Colors.blueAccent,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _TierPreviewScreen())),
          ),
          const SizedBox(height: 12),
          _buildMaintenanceButton(
            context,
            icon: Icons.celebration,
            label: l10n.testConfetti,
            color: Colors.amber.shade800,
            onTap: () {
              AnalyticsService().logAdminMaintenanceAction('test_confetti');
              final isMuted = context.read<AuthProvider>().hushUser?.appSoundsMuted ?? false;
              context.read<UIProvider>().triggerConfetti(muteSound: isMuted);
            },
          ),
          const SizedBox(height: 12),
          _buildMaintenanceButton(
            context,
            icon: Icons.restart_alt,
            label: isHe ? 'איפוס כל המדריכים' : 'Reset All Tutorials',
            color: Colors.redAccent,
            onTap: () {
              final user = context.read<AuthProvider>().firebaseUser;
              if (user != null) {
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .update({
                  'hasSeenTutorial': false,
                  'hasSeenFollowingTutorialV6': false,
                  'hasSeenFeedTutorialV1': false,
                });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isHe ? 'המדריכים אופסו! הפעל מחדש את האפליקציה.' : "Tutorials reset! Restart app.")));
              }
            },
          ),
          const SizedBox(height: 12),
          _buildMaintenanceButton(
            context,
            icon: Icons.notifications_active,
            label: l10n.testPushNotification,
            color: HushColors.gradientPurple,
            onTap: () => _sendTestNotification(context),
          ),
          const SizedBox(height: 12),
          _buildMaintenanceButton(
            context,
            icon: Icons.add_location_alt,
            label: isHe ? 'יצירת האשש עבור הטסטר' : 'Create Hush for Tester',
            color: Colors.green.shade700,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(title: Text(isHe ? 'יצירת סוד מרוחק' : 'Remote Secret')),
                    body: const CreateScreen(
                      targetLat: 32.16596,
                      targetLng: 35.02130,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceButton(BuildContext context, {required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Flexible(child: Text(label, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}

class _TierPreviewScreen extends StatelessWidget {
  const _TierPreviewScreen();

  @override
  Widget build(BuildContext context) {
    final isHe = Localizations.localeOf(context).languageCode == 'he';
    return Scaffold(
      appBar: AppBar(title: Text(isHe ? '🎨 צבעי הדרגות' : '🎨 Tier Colors')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            isHe
                ? 'הדמיית כרטיסיות האשש עבור כל דרגה עם צבע ההילה הייחודי שלה'
                : 'Simulated Hushhh cards showing each tier\'s halo color',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ...List.generate(10, (i) {
            final tier = i + 1;
            final color = HushColors.tierColor(tier);
            final tierNamesHe = [
              'בסיסי (Default)', 'מתחיל (Novice)', 'חבר (Member)',
              'מקצוען (Pro)', 'מומחה (Expert)', 'מאסטר (Master)',
              'רב-אמן עליון (Grandmaster)', 'אגדה (Legend)',
              'מיתולוגי (Mythic)', 'דרגת אל (God Tier)',
            ];
            final tierNamesEn = [
              'Default', 'Novice', 'Member',
              'Pro', 'Expert', 'Master',
              'Grandmaster', 'Legend',
              'Mythic', 'God Tier',
            ];
            final requiredSuccesses = [0, 5, 15, 30, 50, 75, 105, 140, 180, 230];

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: HushColors.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '$tier',
                        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${isHe ? 'דרגה' : 'Tier'} $tier — ${isHe ? tierNamesHe[i] : tierNamesEn[i]}',
                          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isHe
                              ? 'נדרשות ${requiredSuccesses[i]} הצלחות קבוצתיות'
                              : '${requiredSuccesses[i]} group successes required',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Small audio player widget for admin reports
class _AdminAudioPlayer extends StatefulWidget {
  final String? audioURL;
  final bool isHe;

  const _AdminAudioPlayer({required this.audioURL, required this.isHe});

  @override
  State<_AdminAudioPlayer> createState() => _AdminAudioPlayerState();
}

class _AdminAudioPlayerState extends State<_AdminAudioPlayer> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing && state.processingState != ProcessingState.completed;
        });
        if (state.processingState == ProcessingState.completed) {
          _player.seek(Duration.zero);
          _player.pause();
        }
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (widget.audioURL == null) return;
    if (_isPlaying) {
      await _player.pause();
    } else {
      if (_player.duration == null) {
        setState(() => _isLoading = true);
        try {
          await _player.setUrl(widget.audioURL!);
          setState(() { _isLoading = false; _hasError = false; });
        } catch (e) {
          setState(() { _isLoading = false; _hasError = true; });
          return;
        }
      }
      await _player.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.audioURL == null) {
      return Row(
        children: [
          const HushIcon(HushIcons.mic, size: 20, color: HushColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            widget.isHe ? 'האשש קולי (לא נמצא קישור)' : 'Voice Secret (no URL found)',
            style: const TextStyle(color: HushColors.textSecondary, fontSize: 13),
          ),
        ],
      );
    }

    return Row(
      children: [
        IconButton(
          onPressed: _isLoading ? null : _togglePlay,
          icon: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: HushColors.textAccent))
              : Icon(
                  _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  color: _hasError ? HushColors.tierRed : HushColors.textAccent,
                  size: 32,
                ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _hasError
                ? (widget.isHe ? 'שגיאה בטעינת האודיו' : 'Error loading audio')
                : (widget.isHe ? 'האשש קולי — לחץ להאזנה' : 'Voice Secret — tap to listen'),
            style: TextStyle(
              color: _hasError ? HushColors.tierRed : HushColors.textAccent,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _PushNotificationView extends StatefulWidget {
  const _PushNotificationView();
  @override
  State<_PushNotificationView> createState() => _PushNotificationViewState();
}

class _PushNotificationViewState extends State<_PushNotificationView> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  bool _isSending = false;

  Future<void> _sendBroadcast(AppLocalizations l10n) async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    
    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields', style: TextStyle(color: Colors.white)), backgroundColor: HushColors.tierRed),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      await FirebaseFirestore.instance.collection('admin_broadcasts').add({
        'title': title,
        'body': body,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
      _titleController.clear();
      _bodyController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Broadcast queued successfully!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e', style: const TextStyle(color: Colors.white)), backgroundColor: HushColors.tierRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isHe = Localizations.localeOf(context).languageCode == 'he';

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text(
            isHe ? 'שליחת הודעת פוש לכלל המשתמשים' : 'Send Push Notification to ALL users',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _titleController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: isHe ? 'כותרת (Title)' : 'Title',
              labelStyle: const TextStyle(color: HushColors.textSecondary),
              filled: true,
              fillColor: HushColors.bgCard,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _bodyController,
            style: const TextStyle(color: Colors.white),
            maxLines: 4,
            decoration: InputDecoration(
              labelText: isHe ? 'תוכן (Body)' : 'Body',
              labelStyle: const TextStyle(color: HushColors.textSecondary),
              filled: true,
              fillColor: HushColors.bgCard,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isSending ? null : () => _sendBroadcast(l10n),
              style: ElevatedButton.styleFrom(
                backgroundColor: HushColors.textAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: _isSending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send, color: Colors.white),
              label: Text(
                _isSending ? (isHe ? 'שולח...' : 'Sending...') : (isHe ? 'שלח פוש לכולם' : 'Send Broadcast'),
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    ));
  }
}

// ============================================================================
// 5. STATISTICS VIEW
// ============================================================================
class _StatisticsView extends StatefulWidget {
  const _StatisticsView();

  @override
  State<_StatisticsView> createState() => _StatisticsViewState();
}

class _StatisticsViewState extends State<_StatisticsView> {
  bool _isLoading = true;
  
  // Stats variables
  int _totalUsers = 0;
  int _onlineUsers = 0;
  int _newUsers7Days = 0;
  
  int _totalSecretsCreated = 0;
  int _totalSecretsDecayed = 0;
  int _activeSecrets = 0;
  
  int _totalReports = 0;
  
  final double _avgSecretLifetime = 2.4; // Mock calculation fallback
  String _savedPercentage = '0%';
  List<String> _topCreatorsList = [];
  String _contentTypeDistribution = 'Text: 0%, Voice: 0%';
  String _reportRate = '0%';
  String _dauWau = 'DAU: 0, WAU: 0';
  String _avgLikesDislikes = 'Likes: 0, Dislikes: 0';
  
  

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final adminUid = authProvider.firebaseUser?.uid;
      final db = FirebaseFirestore.instance;
      
      // 1. Users Stats
      final usersSnap = await db.collection('users').count().get();
      final usersCount = usersSnap.count ?? 0;
      
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final newUsersSnap = await db.collection('users').where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo)).count().get();
      final newUsersCount = newUsersSnap.count ?? 0;
      
      // 2. Global Secrets Stats (All time)
      int secretsCreated = 0;
      int secretsDecayed = 0;
      try {
        final globalStats = await db.collection('stats').doc('global').get();
        if (globalStats.exists) {
          secretsCreated = globalStats.data()?['totalSecretsCreated'] ?? 0;
          secretsDecayed = globalStats.data()?['totalSecretsDecayed'] ?? 0;
        }
      } catch (_) {}

      // 3. Active Secrets & Advanced Stats
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
          if (data['type'] == 'voice') {
            voiceCount++;
          } else {
            textCount++;
          }
          
          totalLikes += (data['likes'] ?? 0) as int;
          totalDislikes += (data['dislikes'] ?? 0) as int;
          
          final creator = data['creatorName'] ?? 'Unknown';
          creatorCounts[creator] = (creatorCounts[creator] ?? 0) + 1;
      }
      
      List<String> topCreatorsTemp = [];
      if (creatorCounts.isNotEmpty) {
          final sorted = creatorCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
          topCreatorsTemp = sorted.take(10).map((e) => '${e.key} (${e.value})').toList();
      }
      
      int totalDocs = secretsQuery.docs.length;
      String savedPct = totalDocs > 0 ? '${((savedCount / totalDocs) * 100).toStringAsFixed(1)}%' : '0%';
      String typeDist = totalDocs > 0 ? 'Text: ${((textCount / totalDocs) * 100).toStringAsFixed(0)}%, Voice: ${((voiceCount / totalDocs) * 100).toStringAsFixed(0)}%' : 'N/A';
      String likesDist = totalDocs > 0 ? 'Likes: ${(totalLikes / totalDocs).toStringAsFixed(1)}, Dislikes: ${(totalDislikes / totalDocs).toStringAsFixed(1)}' : 'N/A';
      
      final dauSnap = await db.collection('users').where('lastActive', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1)))).count().get();
      final wauSnap = await db.collection('users').where('lastActive', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 7)))).count().get();
      

      // 4. Reports
      final reportsSnap = await db.collection('reports').count().get();
      final reportsCount = reportsSnap.count ?? 0;
      
      // 5. Online users RTDB
      int onlineUsersCount = 0;
      try {
        final rtdb = FirebaseDatabase.instance;
        final statusSnap = await rtdb.ref('status').orderByChild('state').equalTo('online').once();
        if (statusSnap.snapshot.value != null) {
          final Map<dynamic, dynamic> statuses = statusSnap.snapshot.value as Map<dynamic, dynamic>;
          statuses.forEach((key, value) {
            if (value['state'] == 'online' && key != adminUid) {
              onlineUsersCount++;
            }
          });
        }
      } catch (e) {
        debugPrint('RTDB error: $e');
      }

      if (mounted) {
        setState(() {
          _totalUsers = usersCount > 0 ? usersCount - 1 : 0; 
          _newUsers7Days = newUsersCount;
          // Total created should be at least active + decayed. If secretsCreated is higher, use it.
          _totalSecretsCreated = (secretsCreated > (activeSecretsCount + secretsDecayed)) 
              ? secretsCreated 
              : (activeSecretsCount + secretsDecayed);
          _totalSecretsDecayed = secretsDecayed;
          _activeSecrets = activeSecretsCount;
          _totalReports = reportsCount;
          _onlineUsers = onlineUsersCount;
          _savedPercentage = savedPct;
          _topCreatorsList = topCreatorsTemp;
          _contentTypeDistribution = typeDist;
          _avgLikesDislikes = likesDist;
          _dauWau = 'DAU: ${dauSnap.count ?? 0}, WAU: ${wauSnap.count ?? 0}';
          _reportRate = activeSecretsCount > 0 ? '${((reportsCount / activeSecretsCount) * 100).toStringAsFixed(1)}%' : '0%';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHe = Localizations.localeOf(context).languageCode == 'he';
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: HushColors.textAccent));
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _fetchStats,
        color: HushColors.textAccent,
        backgroundColor: HushColors.bgCard,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Added bottom padding to ensure scrollability
          children: [
          _StatCard(
            title: isHe ? 'סה"כ משתמשים רשומים' : 'Total Registered Users',
            subtitle: isHe ? 'לא כולל אדמין' : 'Excluding admin',
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
            subtitle: isHe ? 'לא כולל אדמין' : 'Excluding admin',
            value: _onlineUsers.toString(),
            icon: Icons.wifi,
          ),
          const SizedBox(height: 32),
          _StatCard(
            title: isHe ? 'סה"כ Hushhh שנוצרו' : 'Total Secrets Created',
            subtitle: isHe ? 'מכל הזמנים (כולל מחוקים)' : 'All time (including deleted)',
            value: _totalSecretsCreated.toString(),
            icon: Icons.speaker_notes,
            infoText: isHe ? 'הנפח הכולל של הפעילות באפליקציה.' : 'Total volume of activity on the app.',
          ),
          const SizedBox(height: 16),
          _StatCard(
            title: isHe ? 'Hushhh פעילים כרגע' : 'Active Secrets',
            subtitle: isHe ? 'זמינים כרגע במפה/פיד' : 'Currently available on map/feed',
            value: _activeSecrets.toString(),
            icon: Icons.visibility,
          ),
          const SizedBox(height: 16),
          _StatCard(
            title: isHe ? 'Hushhh שנמחקו בדעיכה' : 'Decayed Secrets',
            subtitle: isHe ? 'נמחקו אוטומטית עקב חוסר עניין' : 'Auto-deleted due to inactivity',
            value: _totalSecretsDecayed.toString(),
            icon: Icons.delete_sweep,
            infoText: isHe ? 'מדד לאיכות התוכן. מספר ההאששים שנמחקו כי לא זכו למספיק אינטראקציה.' : 'Measures content quality. Secrets auto-deleted due to low engagement.',
          ),
          const SizedBox(height: 32),
          _StatCard(
            title: isHe ? 'סה"כ דיווחים' : 'Total Reports',
            subtitle: isHe ? 'דיווחים שהוגשו על ידי משתמשים' : 'Reports submitted by users',
            value: _totalReports.toString(),
            icon: Icons.report_problem,
          ),
          const SizedBox(height: 16),
          _StatCard(
            title: isHe ? 'תוחלת חיים של האשש' : 'Avg Secret Lifetime',
            subtitle: isHe ? 'ממוצע' : 'Average',
            value: '${_avgSecretLifetime.toStringAsFixed(1)} h',
            icon: Icons.hourglass_bottom,
            infoText: isHe ? 'הזמן הממוצע (בשעות) שהאשש נמצא באוויר לפני שהוא נמחק ידנית או אוטומטית.' : 'Average time (hours) a secret is live before deletion.',
          ),
          const SizedBox(height: 16),
          _StatCard(
            title: isHe ? 'אחוז שמירות' : 'Saved Percentage',
            subtitle: isHe ? 'מתוך סך ההאששים' : 'Of all secrets',
            value: _savedPercentage,
            icon: Icons.bookmark_border,
            infoText: isHe ? 'אחוז ההאששים שנשמרו על ידי משתמש לפחות פעם אחת מתוך סך ההאששים הקיימים.' : 'Percentage of active secrets that were saved at least once.',
          ),
          const SizedBox(height: 16),
          _StatCard(
            title: isHe ? 'יוצרים מובילים (Top 10)' : 'Top 10 Creators',
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
            subtitle: isHe ? 'יחס' : 'Ratio',
            value: _contentTypeDistribution,
            icon: Icons.pie_chart_outline,
            infoText: isHe ? 'מראה אילו סוגי תוכן מועדפים על המשתמשים באפליקציה.' : 'Shows what content formats users prefer.',
          ),
          const SizedBox(height: 16),
          _StatCard(
            title: isHe ? 'שיעור דיווחים' : 'Report Rate',
            subtitle: isHe ? 'אחוז האששים מדווחים' : '% of reported secrets',
            value: _reportRate,
            icon: Icons.report_problem_outlined,
            infoText: isHe ? 'כמה אחוז מכלל ההאששים הם האששים שדווחו. עוזר להבין את רמת הבעייתיות של התוכן.' : 'Percentage of active secrets that were reported.',
          ),
          const SizedBox(height: 16),
          _StatCard(
            title: isHe ? 'משתמשים פעילים (DAU/WAU)' : 'Active Users (DAU/WAU)',
            subtitle: isHe ? 'יומי / שבועי' : 'Daily / Weekly',
            value: _dauWau,
            icon: Icons.trending_up,
            infoText: isHe ? 'מדד השימור של האפליקציה (Retention).\nDAU - כמה משתמשים היו פעילים ביממה האחרונה.\nWAU - כמה משתמשים היו פעילים בשבוע האחרון.' : 'User retention metric.\nDAU = Active in last 24h.\nWAU = Active in last 7 days.',
          ),
          const SizedBox(height: 16),
          _StatCard(
            title: isHe ? 'ממוצע לייקים/דיסלייקים' : 'Avg Likes/Dislikes',
            subtitle: isHe ? 'להאשש' : 'Per secret',
            value: _avgLikesDislikes,
            icon: Icons.thumbs_up_down,
            infoText: isHe ? 'סנטימנט האפליקציה: האם המשתמשים נוטים יותר לפרגן או להביע חוסר הסכמה.' : 'App sentiment: Do users tend to like or dislike content more?',
          ),
        ],
      ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final IconData icon;
  final String? infoText;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    this.infoText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HushColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HushColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: HushColors.textAccent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: HushColors.textAccent, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (infoText != null)
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              backgroundColor: HushColors.bgCard,
                              title: Text(title, style: const TextStyle(color: Colors.white)),
                              content: Text(infoText!, style: const TextStyle(color: Colors.white70)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('OK', style: TextStyle(color: HushColors.textAccent)),
                                ),
                              ],
                            ),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Icon(Icons.info_outline, color: HushColors.textMuted, size: 20),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: HushColors.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                value,
                style: const TextStyle(
                  color: HushColors.textAccent,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          if (onTap != null)
            const Padding(
              padding: EdgeInsets.only(left: 8.0, right: 4.0),
              child: Icon(Icons.arrow_forward_ios, color: HushColors.textAccent, size: 16),
            ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: cardContent,
      );
    }
    return cardContent;
  }
}

class TopCreatorsScreen extends StatelessWidget {
  final List<String> creators;
  final bool isHe;

  const TopCreatorsScreen({super.key, required this.creators, required this.isHe});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HushColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: HushColors.bgCard,
        title: Text(isHe ? 'היוצרים המובילים (Top 10)' : 'Top 10 Creators', style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: creators.isEmpty
          ? Center(child: Text(isHe ? 'אין נתונים' : 'No data', style: const TextStyle(color: Colors.white70)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: creators.length,
              itemBuilder: (context, index) {
                return Card(
                  color: HushColors.bgCard,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: HushColors.textAccent,
                      child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(creators[index], style: const TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                );
              },
            ),
    );
  }
}

