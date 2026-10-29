import 'package:flutter_test/flutter_test.dart';
import 'package:rent_a_wedding_dress/main.dart';

void main() {
  testWidgets('App builds and shows login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    expect(find.text('Login'), findsWidgets);
  });
}
