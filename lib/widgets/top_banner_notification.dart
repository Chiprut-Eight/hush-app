import 'dart:async';
import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Displays a sleek, native-feeling top notification banner that animates
/// in from the top of the screen (under SafeArea / Dynamic Island / Notch)
/// and auto-dismisses. This ensures it is not covered by iOS's screenshot
/// thumbnail preview animation at the bottom-left of the screen.
class TopBannerNotification {
  static OverlayEntry? _activeEntry;

  static void show({
    required BuildContext context,
    required String message,
    required IconData icon,
    Color backgroundColor = HushColors.tierRed,
    Duration duration = const Duration(seconds: 4),
  }) {
    // Dismiss any existing banner immediately
    _activeEntry?.remove();
    _activeEntry = null;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _TopBannerWidget(
        message: message,
        icon: icon,
        backgroundColor: backgroundColor,
        duration: duration,
        onDismiss: () {
          if (_activeEntry == entry) {
            entry.remove();
            _activeEntry = null;
          }
        },
      ),
    );

    _activeEntry = entry;
    overlay.insert(entry);
  }
}

class _TopBannerWidget extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color backgroundColor;
  final Duration duration;
  final VoidCallback onDismiss;

  const _TopBannerWidget({
    required this.message,
    required this.icon,
    required this.backgroundColor,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_TopBannerWidget> createState() => _TopBannerWidgetState();
}

class _TopBannerWidgetState extends State<_TopBannerWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;
  late final Animation<double> _fadeAnimation;
  Timer? _autoDismissTimer;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();

    _autoDismissTimer = Timer(widget.duration, () {
      _dismiss();
    });
  }

  Future<void> _dismiss() async {
    if (_isDismissing || !mounted) return;
    _isDismissing = true;
    _autoDismissTimer?.cancel();
    try {
      await _controller.reverse();
    } catch (_) {}
    if (mounted) {
      widget.onDismiss();
    }
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SlideTransition(
            position: _offsetAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: GestureDetector(
                onTap: _dismiss,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: widget.backgroundColor,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(widget.icon, color: Colors.white, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
