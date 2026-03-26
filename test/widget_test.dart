import 'package:flutter_test/flutter_test.dart';
import 'package:hush_app/main.dart';

void main() {
  testWidgets('HUSH app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const HushApp());
  });
}
