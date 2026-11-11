import 'package:flutter_test/flutter_test.dart';
import 'package:dapur_flow/main.dart';

void main() {
  testWidgets('App initializes', (WidgetTester tester) async {
    await tester.pumpWidget(const AturAjahApp());
  });
}
