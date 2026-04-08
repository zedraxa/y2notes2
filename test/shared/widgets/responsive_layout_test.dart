import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:biscuits/shared/widgets/responsive_layout.dart';

void main() {
  group('Breakpoints', () {
    Widget buildWithWidth(double width, Widget child) => MediaQuery(
          data: MediaQueryData(size: Size(width, 800)),
          child: MaterialApp(home: child),
        );

    testWidgets('isPhone returns true for narrow screens', (tester) async {
      late bool result;
      await tester.pumpWidget(
        buildWithWidth(
          375,
          Builder(builder: (context) {
            result = Breakpoints.isPhone(context);
            return const SizedBox();
          }),
        ),
      );
      expect(result, true);
    });

    testWidgets('isTablet returns true for medium screens', (tester) async {
      late bool result;
      await tester.pumpWidget(
        buildWithWidth(
          768,
          Builder(builder: (context) {
            result = Breakpoints.isTablet(context);
            return const SizedBox();
          }),
        ),
      );
      expect(result, true);
    });

    testWidgets('isLargeTablet returns true for wide screens', (tester) async {
      late bool result;
      await tester.pumpWidget(
        buildWithWidth(
          1200,
          Builder(builder: (context) {
            result = Breakpoints.isLargeTablet(context);
            return const SizedBox();
          }),
        ),
      );
      expect(result, true);
    });

    testWidgets('responsive returns correct value per breakpoint',
        (tester) async {
      late String result;

      // Phone
      await tester.pumpWidget(
        buildWithWidth(
          375,
          Builder(builder: (context) {
            result = Breakpoints.responsive(
              context,
              phone: 'phone',
              tablet: 'tablet',
              largeTablet: 'largeTablet',
            );
            return const SizedBox();
          }),
        ),
      );
      expect(result, 'phone');

      // Tablet
      await tester.pumpWidget(
        buildWithWidth(
          768,
          Builder(builder: (context) {
            result = Breakpoints.responsive(
              context,
              phone: 'phone',
              tablet: 'tablet',
              largeTablet: 'largeTablet',
            );
            return const SizedBox();
          }),
        ),
      );
      expect(result, 'tablet');

      // Large tablet
      await tester.pumpWidget(
        buildWithWidth(
          1200,
          Builder(builder: (context) {
            result = Breakpoints.responsive(
              context,
              phone: 'phone',
              tablet: 'tablet',
              largeTablet: 'largeTablet',
            );
            return const SizedBox();
          }),
        ),
      );
      expect(result, 'largeTablet');
    });

    testWidgets('contentPadding varies by screen size', (tester) async {
      late double padding;

      // Phone
      await tester.pumpWidget(
        buildWithWidth(
          375,
          Builder(builder: (context) {
            padding = Breakpoints.contentPadding(context);
            return const SizedBox();
          }),
        ),
      );
      expect(padding, 16.0);

      // Tablet
      await tester.pumpWidget(
        buildWithWidth(
          768,
          Builder(builder: (context) {
            padding = Breakpoints.contentPadding(context);
            return const SizedBox();
          }),
        ),
      );
      expect(padding, 24.0);
    });
  });

  group('ResponsiveLayout', () {
    testWidgets('renders phone widget on narrow screens', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(375, 800)),
          child: MaterialApp(
            home: ResponsiveLayout(
              phone: const Text('phone'),
              tablet: const Text('tablet'),
            ),
          ),
        ),
      );

      expect(find.text('phone'), findsOneWidget);
      expect(find.text('tablet'), findsNothing);
    });

    testWidgets('renders tablet widget on medium screens', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(768, 1024)),
          child: MaterialApp(
            home: ResponsiveLayout(
              phone: const Text('phone'),
              tablet: const Text('tablet'),
            ),
          ),
        ),
      );

      expect(find.text('phone'), findsNothing);
      expect(find.text('tablet'), findsOneWidget);
    });
  });
}
