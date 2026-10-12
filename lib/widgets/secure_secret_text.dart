import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A widget that renders secret text normally to the user,
/// but automatically blacks out during iOS screenshots and screen recordings
/// using an isolated native secure layer without affecting any other screen or modal.
///
/// On Android, standard Text is rendered because Android is already protected
/// system-wide via FLAG_SECURE.
class SecureSecretText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final bool isRtl;

  const SecureSecretText({
    super.key,
    required this.text,
    this.style = const TextStyle(color: Colors.white, fontSize: 16, height: 1.4),
    this.isRtl = true,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || !Platform.isIOS) {
      return Text(
        text,
        style: style,
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth > 0
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width - 48;

        final textPainter = TextPainter(
          text: TextSpan(
            text: text,
            style: style,
          ),
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        )..layout(maxWidth: maxWidth);

        // Add small padding buffer to prevent clipping
        final double height = (textPainter.height + 10).clamp(28.0, 800.0);

        return SizedBox(
          width: double.infinity,
          height: height,
          child: UiKitView(
            viewType: 'hush_secure_text_view',
            layoutDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            creationParams: {
              'text': text,
              'fontSize': style.fontSize ?? 16.0,
              'isRtl': isRtl,
            },
            creationParamsCodec: const StandardMessageCodec(),
          ),
        );
      },
    );
  }
}
