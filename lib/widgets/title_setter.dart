import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ui_provider.dart';

class TitleSetter extends StatefulWidget {
  final String title;
  final Widget child;

  const TitleSetter({super.key, required this.title, required this.child});

  @override
  State<TitleSetter> createState() => _TitleSetterState();
}

class _TitleSetterState extends State<TitleSetter> {
  late UIProvider _uiProvider;

  @override
  void initState() {
    super.initState();
    _uiProvider = context.read<UIProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _uiProvider.pushTitle(widget.title);
    });
  }

  @override
  void didUpdateWidget(covariant TitleSetter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Swap the top title with the new one
        _uiProvider.popTitle();
        _uiProvider.pushTitle(widget.title);
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _uiProvider.popTitle();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
