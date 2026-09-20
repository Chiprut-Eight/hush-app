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
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: HushColors.bgPrimary,
        appBar: AppBar(
          title: Text(l10n.adminTitle),
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: TabBar(
            indicatorColor: HushColors.textAccent,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
            tabs: [
              Tab(text: l10n.appeals),
              Tab(text: l10n.reports),
              Tab(text: l10n.maintenanceTitle),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _AppealsList(),
            _ReportsList(),
            _MaintenanceView(),
          ],
        ),
      ),
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
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: Text(
                                  isHe ? 'אשר ובטל עונש' : 'Approve & Unban',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _handleDecision(context, doc.reference, userId, displayName, false),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: HushColors.tierRed),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: Text(
                                  isHe ? 'דחה ערעור' : 'Reject',
                                  style: const TextStyle(color: HushColors.tierRed, fontWeight: FontWeight.bold),
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

    // Show duration picker modal
    final duration = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: HushColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isHe ? '🗑️ מחיקת האשש וענישת יוצר' : '🗑️ Delete Secret & Punish Creator',
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
                        ? 'פעולה זו תמחק לצמיתות את ההאשש ותעביר את היוצר למצב רפאים:'
                        : 'This will permanently delete the secret and put the creator in Ghost Mode:',
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

    // 2. Delete secret document & subcollection
    if (secretId.isNotEmpty) {
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
                        Row(
                          children: [
                            const HushIcon(HushIcons.mic, size: 20, color: HushColors.textAccent),
                            const SizedBox(width: 8),
                            Text(
                              isHe ? 'האשש קולי (דורש נגן להאזנה)' : 'Voice Secret (Audio)',
                              style: const TextStyle(color: HushColors.textAccent, fontSize: 13),
                            ),
                          ],
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
                      Text(
                        isHe ? '📣 פרטי המדווח:' : '📣 Reporter Details:',
                        style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${isHe ? 'מדווח על ידי:' : 'Reported by:'} $reporterDisplayName',
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
                      child: ElevatedButton.icon(
                        onPressed: () => _handleDeleteAndPunish(
                          context,
                          secretId,
                          creatorId,
                          creatorDisplayName,
                          creatorEmail,
                          reporterDisplayName,
                        ),
                        icon: const Icon(Icons.delete_forever, size: 18, color: Colors.white),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            isHe ? 'מחק והעבר למצב רפאים' : 'Delete & Ghost',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HushColors.tierRed,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
class _MaintenanceView extends StatefulWidget {
  const _MaintenanceView();

  @override
  State<_MaintenanceView> createState() => _MaintenanceViewState();
}

class _MaintenanceViewState extends State<_MaintenanceView> {
  bool _isMigrating = false;
  String? _status;

  Future<void> _sendTestNotification(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final isHe = Localizations.localeOf(context).languageCode == 'he';
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'hush_general_channel',
      'General Notifications',
      channelDescription: 'App alerts and updates',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
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

  String _getStatus(AppLocalizations l10n) {
    if (_status == null) return l10n.migrationReady;
    return _status!;
  }

  Future<void> _migrateSearchNames(AppLocalizations l10n) async {
    setState(() {
      _isMigrating = true;
      _status = l10n.migrationFetching;
    });

    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('searchName', isEqualTo: '')
          .limit(100)
          .get();

      if (query.docs.isEmpty) {
        final queryMissing = await FirebaseFirestore.instance
            .collection('users')
            .orderBy('uid')
            .limit(100)
            .get();

        final docsToUpdate = queryMissing.docs.where((doc) {
          final data = doc.data();
          return !data.containsKey('searchName');
        }).toList();

        if (docsToUpdate.isEmpty) {
          setState(() {
            _isMigrating = false;
            _status = l10n.migrationAllDone;
          });
          return;
        }

        await _performBatchUpdate(docsToUpdate);
      } else {
        await _performBatchUpdate(query.docs);
      }

      AnalyticsService().logAdminMaintenanceAction('migrate_search_names', details: 'success');

      setState(() {
        _isMigrating = false;
        _status = l10n.migrationBatchDone;
      });
    } catch (e) {
      setState(() {
        _isMigrating = false;
        _status = l10n.migrationError(e.toString());
      });
    }
  }

  Future<void> _performBatchUpdate(List<QueryDocumentSnapshot> docs) async {
    final batch = FirebaseFirestore.instance.batch();
    int count = 0;

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final firstName = data['firstName'] ?? '';
      final lastName = data['lastName'] ?? '';
      final displayName = data['displayName'] ?? '';

      String searchName = '';
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        searchName = '$firstName $lastName'.trim().toLowerCase();
      } else if (displayName.isNotEmpty) {
        searchName = displayName.toLowerCase();
      }

      batch.update(doc.reference, {'searchName': searchName});
      count++;
    }

    if (count > 0) {
      await batch.commit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isHe = Localizations.localeOf(context).languageCode == 'he';

    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        // === Tier Color Preview Section ===
        Text(
          isHe ? '🎨 תצוגה מקדימה של צבעי הדרגות' : '🎨 Tier Color Preview',
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          isHe
              ? 'הדמיית כרטיסיות האשש עבור כל דרגה עם צבע ההילה הייחודי שלה'
              : 'Simulated Hushhh cards showing each tier\'s halo color',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
        const SizedBox(height: 18),
        ...List.generate(10, (i) {
          final tier = i + 1;
          final color = HushColors.tierColor(tier);
          final tierNamesHe = [
            'בסיסי (Default)', 'מתחיל (Novice)', 'שוליה (Apprentice)',
            'מיומן (Adept)', 'מומחה (Expert)', 'מאסטר (Master)',
            'רב-אמן עליון (Grandmaster)', 'אגדה (Legend)',
            'מיתולוגי (Mythic)', 'דרגת אל (God Tier)',
          ];
          final tierNamesEn = [
            'Default', 'Novice', 'Apprentice',
            'Adept', 'Expert', 'Master',
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

        const Divider(height: 48, color: Colors.white10),

        // === Migration & Test Tools ===
        Text(
          isHe ? '🛠️ כלי תחזוקה ובדיקות' : '🛠️ Maintenance & Testing Tools',
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton.icon(
            onPressed: () {
              AnalyticsService().logAdminMaintenanceAction('test_confetti');
              final isMuted = context.read<AuthProvider>().hushUser?.appSoundsMuted ?? false;
              context.read<UIProvider>().triggerConfetti(muteSound: isMuted);
            },
            icon: const Icon(Icons.celebration),
            label: Text(l10n.testConfetti),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade800,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: ElevatedButton.icon(
            onPressed: () => _sendTestNotification(context),
            icon: const Icon(Icons.notifications_active),
            label: Text(l10n.testPushNotification),
            style: ElevatedButton.styleFrom(
              backgroundColor: HushColors.gradientPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Divider(height: 32, color: Colors.white10),
        Text(
          l10n.migrationSearchTitle,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          l10n.migrationSearchDesc,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
        ),
        const SizedBox(height: 16),
        Center(
          child: _isMigrating
              ? const CircularProgressIndicator(color: HushColors.textAccent)
              : ElevatedButton(
                  onPressed: () => _migrateSearchNames(l10n),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: Text(l10n.migrateUsers),
                ),
        ),
        const SizedBox(height: 12),
        Center(child: Text(_getStatus(l10n), style: const TextStyle(color: Colors.white54, fontSize: 12))),
        const SizedBox(height: 24),
      ],
    );
  }
}
