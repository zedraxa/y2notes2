import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:biscuits/features/documents/domain/entities/notebook.dart';

void main() {
  group('CoverPattern', () {
    test('has 8 values', () {
      expect(CoverPattern.values.length, 8);
    });

    test('none is the first value', () {
      expect(CoverPattern.values.first, CoverPattern.none);
    });

    test('name round-trips through byName', () {
      for (final p in CoverPattern.values) {
        expect(CoverPattern.values.byName(p.name), p);
      }
    });
  });

  group('CoverEmblem', () {
    test('has 8 values', () {
      expect(CoverEmblem.values.length, 8);
    });

    test('none is the first value', () {
      expect(CoverEmblem.values.first, CoverEmblem.none);
    });

    test('name round-trips through byName', () {
      for (final e in CoverEmblem.values) {
        expect(CoverEmblem.values.byName(e.name), e);
      }
    });
  });

  group('NotebookCoverConfig', () {
    test('default values', () {
      const config = NotebookCoverConfig();
      expect(config.color, const Color(0xFF2563EB));
      expect(config.material, CoverMaterial.matte);
      expect(config.pattern, CoverPattern.none);
      expect(config.emblem, CoverEmblem.none);
    });

    test('copyWith updates all fields', () {
      const original = NotebookCoverConfig();
      final updated = original.copyWith(
        color: const Color(0xFFDC2626),
        material: CoverMaterial.leather,
        pattern: CoverPattern.chevron,
        emblem: CoverEmblem.star,
      );
      expect(updated.color, const Color(0xFFDC2626));
      expect(updated.material, CoverMaterial.leather);
      expect(updated.pattern, CoverPattern.chevron);
      expect(updated.emblem, CoverEmblem.star);
    });

    test('copyWith preserves original when no arguments given', () {
      const original = NotebookCoverConfig(
        color: Color(0xFF16A34A),
        material: CoverMaterial.canvas,
        pattern: CoverPattern.dots,
        emblem: CoverEmblem.leaf,
      );
      final copy = original.copyWith();
      expect(copy, original);
    });

    test('toJson omits pattern and emblem when they are none', () {
      const config = NotebookCoverConfig();
      final json = config.toJson();
      expect(json.containsKey('pattern'), isFalse);
      expect(json.containsKey('emblem'), isFalse);
      expect(json['color'], const Color(0xFF2563EB).value);
      expect(json['material'], 'matte');
    });

    test('toJson includes pattern and emblem when set', () {
      const config = NotebookCoverConfig(
        pattern: CoverPattern.plaid,
        emblem: CoverEmblem.moon,
      );
      final json = config.toJson();
      expect(json['pattern'], 'plaid');
      expect(json['emblem'], 'moon');
    });

    test('fromJson round-trips correctly with all fields', () {
      const original = NotebookCoverConfig(
        color: Color(0xFF7C3AED),
        material: CoverMaterial.glossy,
        pattern: CoverPattern.herringbone,
        emblem: CoverEmblem.crown,
      );
      final json = original.toJson();
      final restored = NotebookCoverConfig.fromJson(json);
      expect(restored, original);
    });

    test('fromJson handles missing pattern and emblem gracefully', () {
      final json = {'color': 0xFF2563EB, 'material': 'matte'};
      final config = NotebookCoverConfig.fromJson(json);
      expect(config.pattern, CoverPattern.none);
      expect(config.emblem, CoverEmblem.none);
    });

    test('fromLegacyName returns default pattern and emblem', () {
      final config = NotebookCoverConfig.fromLegacyName('blue');
      expect(config.pattern, CoverPattern.none);
      expect(config.emblem, CoverEmblem.none);
      expect(config, NotebookCoverConfig.azure);
    });

    test('equality includes pattern and emblem', () {
      const a = NotebookCoverConfig(pattern: CoverPattern.dots);
      const b = NotebookCoverConfig(pattern: CoverPattern.stripes);
      const c = NotebookCoverConfig(pattern: CoverPattern.dots);
      expect(a, isNot(b));
      expect(a, c);
    });

    test('rich presets have non-default pattern and emblem', () {
      expect(
        NotebookCoverConfig.classicJournal.pattern,
        CoverPattern.herringbone,
      );
      expect(NotebookCoverConfig.classicJournal.emblem, CoverEmblem.compass);

      expect(NotebookCoverConfig.gardenNotes.pattern, CoverPattern.dots);
      expect(NotebookCoverConfig.gardenNotes.emblem, CoverEmblem.leaf);

      expect(NotebookCoverConfig.nightSky.pattern, CoverPattern.diamond);
      expect(NotebookCoverConfig.nightSky.emblem, CoverEmblem.moon);

      expect(NotebookCoverConfig.royalDiary.pattern, CoverPattern.plaid);
      expect(NotebookCoverConfig.royalDiary.emblem, CoverEmblem.crown);
    });
  });
}
