import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:herzon/presentation/widgets/scale_press.dart';

void main() {
  group('ScalePress', () {
    testWidgets('renders child and responds to tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScalePress(
              onTap: () => tapped = true,
              child: const Text('Press me'),
            ),
          ),
        ),
      );

      expect(find.text('Press me'), findsOneWidget);
      await tester.tap(find.text('Press me'));
      expect(tapped, true);
    });
  });
}
