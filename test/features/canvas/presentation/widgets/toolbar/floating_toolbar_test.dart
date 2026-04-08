import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:biscuits/features/canvas/presentation/widgets/toolbar/floating_toolbar.dart';

void main() {
  group('FloatingToolbar', () {
    test('FloatingToolbar class exists and is a StatefulWidget', () {
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

    test('FloatingToolbar default constructor has null onSettingsTap', () {
      const toolbar = FloatingToolbar();
      expect(toolbar.onSettingsTap, isNull);
    });

    test('FloatingToolbar creates state', () {
      const toolbar = FloatingToolbar();
      final state = toolbar.createState();
      expect(state, isNotNull);
    });
  });
}
