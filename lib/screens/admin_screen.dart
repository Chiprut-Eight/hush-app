import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hush_app/config/theme.dart';
import 'package:hush_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../providers/ui_provider.dart';
import '../core/constants/icons.dart';
import '../widgets/hush_icon_widget.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

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

class _AppealsList extends StatelessWidget {
  const _AppealsList();

  Future<void> _handleDecision(DocumentReference appealRef, String userId, bool approve) async {
    // 1. Update the appeal status
    await appealRef.update({'status': approve ? 'approved' : 'rejected'});

    // 2. If approved, lift Ghost Mode directly in the users collection
    if (approve && userId.isNotEmpty) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isGhostMode': false,
        'ghostModeUntil': FieldValue.delete(),
        'reportsCount': 0 // Reset reports count optionally
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
          return tb.compareTo(ta); // Descending (Newest first)
        });

        return ListView(
          padding: const EdgeInsets.all(16),
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final date = (data['createdAt'] as Timestamp?)?.toDate();
            final userId = data['userId'] ?? '';
            
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
                        Text(data['userEmail'] ?? 'Unknown Email', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        if (date != null)
                          Text('${date.day}/${date.month}/${date.year}', style: const TextStyle(color: HushColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(data['reason'] ?? 'No reason provided.', style: const TextStyle(color: Colors.white70, height: 1.4)),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _handleDecision(doc.reference, userId, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: HushColors.textAccent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Approve & Unban', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _handleDecision(doc.reference, userId, false),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: HushColors.tierRed),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Reject', style: TextStyle(color: HushColors.tierRed)),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _ReportsList extends StatelessWidget {
  const _ReportsList();

  Future<void> _handleReport(DocumentReference reportRef, String secretId, bool deleteSecret) async {
    // Determine the report as reviewed
    await reportRef.update({'status': 'reviewed'});

    // If deemed harmful, physically delete the bad secret document across the network
    if (deleteSecret && secretId.isNotEmpty) {
      await FirebaseFirestore.instance.collection('secrets').doc(secretId).delete();
    }
  }

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
          return tb.compareTo(ta); // Descending (Newest first)
        });

        return ListView(
          padding: const EdgeInsets.all(16),
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final date = (data['createdAt'] as Timestamp?)?.toDate();
            final secretId = data['secretId'] ?? '';

            return Card(
              color: HushColors.bgCard,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Secret ID: $secretId', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Reporter ID: ${data['reporterId']}', style: const TextStyle(color: HushColors.textSecondary, fontSize: 11)),
                    if (data['reporterName'] != null || data['reporterEmail'] != null) ...[
                      const SizedBox(height: 4),
                      Text('Reporter: ${data['reporterName'] ?? 'N/A'}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      Text('Email: ${data['reporterEmail'] ?? 'N/A'}', style: const TextStyle(color: HushColors.textAccent, fontSize: 12)),
                    ] else ...[
                      const SizedBox(height: 4),
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('users').doc(data['reporterId']).get(),
                        builder: (context, userSnap) {
                          if (userSnap.connectionState == ConnectionState.waiting) return const SizedBox(height: 20);
                          if (!userSnap.hasData || !userSnap.data!.exists) return const Text('User lookup failed', style: TextStyle(color: HushColors.tierRed, fontSize: 12));
                          final uData = userSnap.data!.data() as Map<String, dynamic>;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Reporter: ${uData['firstName'] ?? ''} ${uData['lastName'] ?? ''}'.trim(), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                              Text('Email: ${uData['email'] ?? 'N/A'}', style: const TextStyle(color: HushColors.textAccent, fontSize: 12)),
                              const SizedBox(height: 12),
                              Text('Reason: ${data['reason'] ?? 'Not specified'}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                              const SizedBox(height: 12),
                            ],
                          );
                        }
                      ),
                    ],
                    if (date != null) ...[
                      const SizedBox(height: 4),
                      Text('${date.day}/${date.month}/${date.year}', style: const TextStyle(color: HushColors.textMuted, fontSize: 12)),
                    ],
                    const SizedBox(height: 16),
                    
                    // Display Secret Context
                    const Divider(color: Colors.white24),
                    const Text('Reported Content:', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('secrets').doc(secretId).get(),
                      builder: (context, secretSnap) {
                        if (secretSnap.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator(strokeWidth: 2);
                        }
                        if (!secretSnap.hasData || !secretSnap.data!.exists) {
                          return const Text('Secret has already been deleted or missing.', style: TextStyle(color: HushColors.textMuted, fontSize: 14));
                        }
                        
                        final sData = secretSnap.data!.data() as Map<String, dynamic>?;
                        if (sData == null) return const SizedBox();
                        
                        if (sData['type'] == 'voice') {
                          return Row(
                            children: [
                              HushIcon(HushIcons.mic, size: 20, color: HushColors.textAccent),
                              const SizedBox(width: 8),
                              const Text('Voice Secret - Requires App Player to listen', style: TextStyle(color: HushColors.textAccent)),
                            ],
                          );
                        } else {
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                            child: Text(sData['textContent'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 15)),
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _handleReport(doc.reference, secretId, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: HushColors.tierRed,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Delete Secret', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _handleReport(doc.reference, secretId, false),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white54),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Dismiss Report', style: TextStyle(color: Colors.white)),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _MaintenanceView extends StatefulWidget {
  const _MaintenanceView();

  @override
  State<_MaintenanceView> createState() => _MaintenanceViewState();
}

class _MaintenanceViewState extends State<_MaintenanceView> {
  bool _isMigrating = false;
  String? _status;

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
        // Also check for users where the field doesn't exist at all
        final queryMissing = await FirebaseFirestore.instance
            .collection('users')
            .orderBy('uid')
            .limit(100)
            .get();
        
        // Filter in memory for simplicity of migration script logic
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.build_circle_outlined, size: 64, color: HushColors.textAccent),
            const SizedBox(height: 16),
            Text(
              l10n.migrationSearchTitle,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.migrationSearchDesc,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 32),
            if (_isMigrating)
              const CircularProgressIndicator(color: HushColors.textAccent)
            else
              ElevatedButton(
                onPressed: () => _migrateSearchNames(l10n),
                child: Text(l10n.migrateUsers),
              ),
            const SizedBox(height: 16),
            Text(_getStatus(l10n), style: const TextStyle(color: Colors.white54)),
            const Divider(height: 64, color: Colors.white10),
            ElevatedButton.icon(
              onPressed: () => context.read<UIProvider>().triggerConfetti(),
              icon: const Icon(Icons.celebration),
              label: Text(l10n.testConfetti),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade800,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
