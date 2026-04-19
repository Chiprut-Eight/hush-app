import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../config/theme.dart';
import '../core/constants/icons.dart';
import '../widgets/hush_icon_widget.dart';

class NotificationsButton extends StatelessWidget {
  const NotificationsButton({super.key});

  void _showNotificationsMenu(BuildContext context) {
    final uid = context.read<AuthProvider>().firebaseUser?.uid;
    if (uid == null) return;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final langCode = Localizations.localeOf(context).languageCode;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? HushColors.bgPrimary : HushColors.bgPrimaryLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.7,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: HushColors.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    langCode == 'he' ? 'התראות אחרונות' : 'Recent Notifications', 
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)
                  ),
                ),
                const Divider(color: HushColors.borderSubtle, height: 1),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .collection('notifications')
                        .orderBy('createdAt', descending: true)
                        .limit(30)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: HushColors.textAccent));
                      }
                      
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Text(
                            langCode == 'he' ? 'אין התראות כרגע' : 'No notifications yet', 
                            style: const TextStyle(color: HushColors.textSecondary)
                          ),
                        );
                      }

                      final docs = snapshot.data!.docs;
                      
                      // Mark all as read silently
                      for (var doc in docs) {
                        if (doc.data() is Map && !(doc.data() as Map)['read']) {
                          doc.reference.update({'read': true}).catchError((_) {});
                        }
                      }

                      return ListView.separated(
                        itemCount: docs.length,
                        separatorBuilder: (context, index) => const Divider(color: HushColors.borderSubtle, height: 1),
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          final titleObj = data['title'] as Map<String, dynamic>?;
                          final bodyObj = data['body'] as Map<String, dynamic>?;
                          
                          final title = titleObj?[langCode] ?? titleObj?['en'] ?? 'Notification';
                          final body = bodyObj?[langCode] ?? bodyObj?['en'] ?? '';
                          final isRead = data['read'] == true;
                          
                          return Container(
                            color: isRead ? Colors.transparent : HushColors.textAccent.withValues(alpha: 0.1),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: HushColors.bgCard,
                                  child: const HushIcon(HushIcons.bell, size: 16, color: HushColors.textAccent),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: TextStyle(
                                          color: isDark ? Colors.white : Colors.black87,
                                          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        body,
                                        style: const TextStyle(
                                          color: HushColors.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().firebaseUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .where('read', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data?.docs.length ?? 0;
        
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: HushIcon(HushIcons.bell, size: 24, color: isDark ? Colors.white : HushColors.textPrimaryLight),
              onPressed: () => _showNotificationsMenu(context),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: HushColors.tierRed,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : unreadCount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
