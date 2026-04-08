import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:biscuits/shared/widgets/biscuits_logo.dart';

void main() {
  group('BiscuitsLogo', () {
    testWidgets('renders icon and text by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: BiscuitsLogo()),
          ),
        ),
      );

      // Should find the "Biscuits" text label
      expect(find.text('Biscuits'), findsOneWidget);

      // Should have a CustomPaint (the icon)
      expect(find.byType(CustomPaint), findsOneWidget);
    });

    testWidgets('hides text when showText is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: BiscuitsLogo(showText: false),
            ),
          ),
        ),
      );

      expect(find.text('Biscuits'), findsNothing);
      expect(find.byType(CustomPaint), findsOneWidget);
    });

    testWidgets('respects custom size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: BiscuitsLogo(size: 120),
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.byType(SizedBox).first,
      );
      expect(sizedBox.width, 120);
      expect(sizedBox.height, 120);
    });

    testWidgets('renders in dark theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: Center(child: BiscuitsLogo()),
          ),
        ),
      );

      expect(find.text('Biscuits'), findsOneWidget);
      expect(find.byType(CustomPaint), findsOneWidget);
    });
  });
}
