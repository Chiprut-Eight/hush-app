import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ui_provider.dart';
import '../providers/auth_provider.dart';
import '../config/theme.dart';
import '../core/constants/icons.dart';
import 'hush_icon_widget.dart';
import 'notifications_button.dart';
import '../main.dart';

class AnimatedAppBar extends StatefulWidget {
  const AnimatedAppBar({super.key});

  @override
  State<AnimatedAppBar> createState() => _AnimatedAppBarState();
}

class _AnimatedAppBarState extends State<AnimatedAppBar> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Start the timer to collapse the app bar after 5 seconds if not already collapsed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uiProvider = context.read<UIProvider>();
      if (!uiProvider.isAppBarCollapsed) {
        _timer = Timer(const Duration(seconds: 5), () {
          if (mounted) {
            context.read<UIProvider>().setAppBarCollapsed(true);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uiProvider = context.watch<UIProvider>();
    final isCollapsed = uiProvider.isAppBarCollapsed;
    final title = uiProvider.currentTitle;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Check if we can pop in the root navigator (meaning we are in a deep screen like Settings)
    final canPop = rootNavigatorKey.currentState?.canPop() ?? false;

    // Check if user is authenticated. If not, don't show the AppBar.
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated || auth.hushUser == null) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      bottom: false,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Full Width Row for the sides
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Start side: The Logo (Always visible)
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      context.read<UIProvider>().triggerNavigateHome();
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // TEXT PART (comes first in reading order)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeInOut,
                          width: isCollapsed ? 0 : 130, // Increased width to fit larger text
                          child: AnimatedOpacity(
                            opacity: isCollapsed ? 0.0 : 1.0,
                            duration: const Duration(milliseconds: 400),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 0.0), // Gap completely removed
                              child: Image.asset(
                                'assets/images/text_only.png',
                                height: 42, // Increased from 38
                                fit: BoxFit.contain,
                                alignment: AlignmentDirectional.centerEnd,
                              ),
                            ),
                          ),
                        ),
                        // ICON PART (comes second)
                        Image.asset(
                          'assets/images/icon_only.png',
                          height: 48,
                          fit: BoxFit.contain,
                        ),
                        // TITLE PART (comes third, appears when collapsed)
                        Expanded(
                          child: AnimatedOpacity(
                            opacity: isCollapsed ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 400),
                            child: Padding(
                              padding: const EdgeInsetsDirectional.only(start: 8.0),
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : HushColors.textPrimaryLight,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.fade,
                                softWrap: false,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // End side: Menu/Back and Notifications
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const NotificationsButton(),
                    if (canPop)
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_rounded, size: 28, color: isDark ? Colors.white : Colors.black87),
                        onPressed: () {
                          rootNavigatorKey.currentState?.pop();
                        },
                      )
                    else
                      IconButton(
                        icon: HushIcon(HushIcons.feed, size: 26, color: isDark ? Colors.white : Colors.black87),
                        onPressed: () {
                          FocusManager.instance.primaryFocus?.unfocus();
                          Scaffold.of(context).openDrawer();
                        },
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
