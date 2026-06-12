import 'package:flutter_test/flutter_test.dart';

import 'package:cliniview_new/main.dart';

void main() {
  testWidgets('Cliniview shows the login experience', (tester) async {
    await tester.pumpWidget(const CliniviewApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in to continue.'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });
}
