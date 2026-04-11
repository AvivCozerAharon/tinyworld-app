import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinyworld_app/app.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: TinyWorldApp()));
    await tester.pumpAndSettle();
    expect(find.byType(TinyWorldApp), findsOneWidget);
  });
}
