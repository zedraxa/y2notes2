import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:biscuits/features/documents/domain/entities/notebook.dart';
import 'package:biscuits/features/library/presentation/widgets/notebook_cover_widget.dart';

void main() {
  group('NotebookCoverWidget', () {
    testWidgets('renders with default parameters', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: NotebookCoverWidget(
                color: Color(0xFF2563EB),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(NotebookCoverWidget), findsOneWidget);
      expect(find.byType(CustomPaint), findsOneWidget);
    });

    testWidgets('renders with pattern and emblem', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: NotebookCoverWidget(
                color: Color(0xFFDC2626),
                material: CoverMaterial.leather,
                pattern: CoverPattern.chevron,
                emblem: CoverEmblem.star,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(NotebookCoverWidget), findsOneWidget);
      expect(find.byType(CustomPaint), findsOneWidget);
    });

    testWidgets('renders title overlay when title is provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: NotebookCoverWidget(
                color: Color(0xFF16A34A),
                title: 'My Notebook',
              ),
            ),
          ),
        ),
      );

      expect(find.text('My Notebook'), findsOneWidget);
    });

    testWidgets('respects custom width and height', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: NotebookCoverWidget(
                color: Color(0xFF7C3AED),
                width: 200,
                height: 300,
              ),
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(NotebookCoverWidget),
          matching: find.byType(SizedBox),
        ),
      );
      expect(sizedBox.width, 200);
      expect(sizedBox.height, 300);
    });

    testWidgets('renders all pattern types without error', (tester) async {
      for (final pattern in CoverPattern.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: NotebookCoverWidget(
                  color: const Color(0xFF2563EB),
                  pattern: pattern,
                ),
              ),
            ),
          ),
        );
        expect(find.byType(NotebookCoverWidget), findsOneWidget);
      }
    });

    testWidgets('renders all emblem types without error', (tester) async {
      for (final emblem in CoverEmblem.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: NotebookCoverWidget(
                  color: const Color(0xFF2563EB),
                  emblem: emblem,
                ),
              ),
            ),
          ),
        );
        expect(find.byType(NotebookCoverWidget), findsOneWidget);
      }
    });

    testWidgets('renders all material types without error', (tester) async {
      for (final material in CoverMaterial.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: NotebookCoverWidget(
                  color: const Color(0xFF2563EB),
                  material: material,
                ),
              ),
            ),
          ),
        );
        expect(find.byType(NotebookCoverWidget), findsOneWidget);
      }
    });

    testWidgets('renders with all options combined', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: NotebookCoverWidget(
                color: Color(0xFF4338CA),
                material: CoverMaterial.linen,
                pattern: CoverPattern.moroccan,
                emblem: CoverEmblem.compass,
                title: 'Travel Journal',
                width: 150,
                height: 200,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(NotebookCoverWidget), findsOneWidget);
      expect(find.text('Travel Journal'), findsOneWidget);
    });
  });
}
