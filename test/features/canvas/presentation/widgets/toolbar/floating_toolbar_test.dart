import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:biscuits/features/canvas/presentation/widgets/toolbar/floating_toolbar.dart';

// We test the publicly exported FloatingToolbar exists and can be imported.
// Full widget tests require Bloc providers which are tested in integration.
void main() {
  group('FloatingToolbar', () {
    test('FloatingToolbar class exists and is a StatefulWidget', () {
      // Verify the class can be instantiated.
      const toolbar = FloatingToolbar();
      expect(toolbar, isA<StatefulWidget>());
    });

    test('FloatingToolbar accepts onSettingsTap callback', () {
      var called = false;
      final toolbar = FloatingToolbar(
        onSettingsTap: () => called = true,
      );
      expect(toolbar.onSettingsTap, isNotNull);
      toolbar.onSettingsTap!();
      expect(called, isTrue);
    });
  });
}
