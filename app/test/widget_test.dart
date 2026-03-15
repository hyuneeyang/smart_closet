import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smart_closet/src/app/app.dart';

void main() {
  testWidgets('앱 쉘이 렌더링된다', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SmartClosetApp(),
      ),
    );

    expect(find.text('스마트 옷장'), findsOneWidget);
  });
}
