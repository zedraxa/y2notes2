import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:biscuits/features/canvas/presentation/widgets/toolbar/floating_toolbar.dart';

void main() {
  group('FloatingToolbar', () {
    test('is a StatefulWidget', () {
      const toolbar = FloatingToolbar();
      expect(toolbar, isA<StatefulWidget>());
    });

    test('accepts onSettingsTap callback', () {
      var called = false;
      final toolbar = FloatingToolbar(
        onSettingsTap: () => called = true,
      );
      expect(toolbar.onSettingsTap, isNotNull);
      toolbar.onSettingsTap!();
      expect(called, isTrue);
    });

    test('default constructor has null onSettingsTap', () {
      const toolbar = FloatingToolbar();
      expect(toolbar.onSettingsTap, isNull);
    });

    test('createState returns non-null state', () {
      const toolbar = FloatingToolbar();
      final state = toolbar.createState();
      expect(state, isNotNull);
    });

    test('multiple instances with different callbacks are independent', () {
      var calls = <String>[];
      final toolbar1 = FloatingToolbar(
        onSettingsTap: () => calls.add('t1'),
      );
      final toolbar2 = FloatingToolbar(
        onSettingsTap: () => calls.add('t2'),
      );

      toolbar1.onSettingsTap!();
      toolbar2.onSettingsTap!();

      expect(calls, ['t1', 't2']);
    });

    test('const constructor produces identical widgets', () {
      // Verifies const propagation is valid.
      const a = FloatingToolbar();
      const b = FloatingToolbar();
      expect(identical(a, b), isTrue);
    });
  });
}
