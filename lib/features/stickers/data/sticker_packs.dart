import 'package:flutter/material.dart';
import 'package:y2notes2/features/stickers/domain/models/stamp_shape.dart';
import 'package:y2notes2/features/stickers/domain/models/washi_pattern.dart';

class StickerPacks {
  StickerPacks._();

  // ─── Emoji packs ────────────────────────────────────────────────────────

  static const Map<String, List<String>> emojiPacks = {
    'Faces': [
      '😀', '😂', '😍', '🥰', '😎', '🤔', '😴', '🥺',
      '😊', '🤩', '😇', '🙃', '😜', '🤗', '😤', '🥳',
    ],
    'Nature': [
      '🌸', '🌺', '🌻', '🌹', '🍀', '🌿', '🍃', '🌱',
      '🌲', '🌳', '🌴', '🎋', '🌾', '🍄', '🌵', '🎍',
    ],
    'Food': [
      '🍎', '🍓', '🍒', '🍑', '🥝', '🍋', '🍊', '🫐',
      '🍇', '🍉', '🥑', '🌮', '🍕', '🍩', '🧁', '🎂',
    ],
    'Animals': [
      '🐶', '🐱', '🐰', '🦊', '🐻', '🐼', '🐨', '🐯',
      '🦁', '🐸', '🐙', '🦋', '🐝', '🦄', '🐳', '🦋',
    ],
    'Objects': [
      '⭐', '🌟', '✨', '💫', '🔥', '❄️', '🌈', '⚡',
      '💎', '🎯', '🎨', '🎭', '🎪', '🎠', '🎡', '🎢',
    ],
    'Symbols': [
      '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍',
      '💔', '❣️', '💕', '💞', '💓', '💗', '💖', '💝',
    ],
  };

  // ─── Stamp packs ─────────────────────────────────────────────────────────

  static const List<StampShape> basicShapes = [
    StampShape(id: 'star', name: 'Star', category: 'basic'),
    StampShape(id: 'heart', name: 'Heart', category: 'basic'),
    StampShape(id: 'circle', name: 'Circle', category: 'basic'),
    StampShape(id: 'square', name: 'Square', category: 'basic'),
    StampShape(id: 'triangle', name: 'Triangle', category: 'basic'),
    StampShape(id: 'diamond', name: 'Diamond', category: 'basic'),
    StampShape(id: 'cross', name: 'Cross', category: 'basic'),
  ];

  static const List<StampShape> arrowShapes = [
    StampShape(id: 'arrow_up', name: 'Arrow Up', category: 'arrows'),
    StampShape(id: 'arrow_down', name: 'Arrow Down', category: 'arrows'),
    StampShape(id: 'arrow_left', name: 'Arrow Left', category: 'arrows'),
    StampShape(id: 'arrow_right', name: 'Arrow Right', category: 'arrows'),
  ];

  static const List<StampShape> natureShapes = [
    StampShape(id: 'leaf', name: 'Leaf', category: 'nature'),
    StampShape(id: 'flower', name: 'Flower', category: 'nature'),
    StampShape(id: 'sun', name: 'Sun', category: 'nature'),
    StampShape(id: 'moon', name: 'Moon', category: 'nature'),
    StampShape(id: 'cloud', name: 'Cloud', category: 'nature'),
    StampShape(id: 'raindrop', name: 'Raindrop', category: 'nature'),
    StampShape(id: 'snowflake', name: 'Snowflake', category: 'nature'),
    StampShape(id: 'tree', name: 'Tree', category: 'nature'),
    StampShape(id: 'mountain', name: 'Mountain', category: 'nature'),
  ];

  static const List<StampShape> decorativeShapes = [
    StampShape(id: 'sparkle', name: 'Sparkle', category: 'decorative'),
    StampShape(id: 'ribbon', name: 'Ribbon', category: 'decorative'),
    StampShape(id: 'banner', name: 'Banner', category: 'decorative'),
    StampShape(id: 'frame', name: 'Frame', category: 'decorative'),
    StampShape(id: 'bracket', name: 'Bracket', category: 'decorative'),
    StampShape(id: 'divider', name: 'Divider', category: 'decorative'),
    StampShape(id: 'corner_ornament', name: 'Corner', category: 'decorative'),
    StampShape(id: 'checkmark', name: 'Checkmark', category: 'decorative'),
  ];

  static List<StampShape> get allStamps => [
        ...basicShapes,
        ...arrowShapes,
        ...natureShapes,
        ...decorativeShapes,
      ];

  // ─── Washi patterns ───────────────────────────────────────────────────────

  static List<WashiPattern> get washiPatterns => [
        const WashiPattern(
          id: 'sakura_pink',
          name: 'Sakura Pink',
          patternType: WashiPatternType.dotted,
          color: Color(0xFFFFB7C5),
          secondaryColor: Color(0xFFFF8FAB),
          opacity: 0.7,
        ),
        const WashiPattern(
          id: 'mint_stripe',
          name: 'Mint Stripe',
          patternType: WashiPatternType.striped,
          color: Color(0xFF98D8C8),
          secondaryColor: Color(0xFFE0F5F0),
          opacity: 0.65,
        ),
        const WashiPattern(
          id: 'lavender_solid',
          name: 'Lavender',
          patternType: WashiPatternType.solid,
          color: Color(0xFFCDB4DB),
          opacity: 0.6,
        ),
        const WashiPattern(
          id: 'golden_stripe',
          name: 'Golden Stripe',
          patternType: WashiPatternType.striped,
          color: Color(0xFFFFD700),
          secondaryColor: Color(0xFFFFF5CC),
          opacity: 0.7,
        ),
        const WashiPattern(
          id: 'ocean_blue',
          name: 'Ocean Blue',
          patternType: WashiPatternType.striped,
          color: Color(0xFF87CEEB),
          secondaryColor: Color(0xFFE0F4FF),
          opacity: 0.65,
        ),
        const WashiPattern(
          id: 'rose_dotted',
          name: 'Rose Dotted',
          patternType: WashiPatternType.dotted,
          color: Color(0xFFE8A0BF),
          secondaryColor: Color(0xFFFFF0F5),
          opacity: 0.7,
        ),
        const WashiPattern(
          id: 'forest_green',
          name: 'Forest Green',
          patternType: WashiPatternType.solid,
          color: Color(0xFF90C695),
          opacity: 0.6,
        ),
        const WashiPattern(
          id: 'sunset_orange',
          name: 'Sunset Orange',
          patternType: WashiPatternType.striped,
          color: Color(0xFFFFB347),
          secondaryColor: Color(0xFFFFF0E0),
          opacity: 0.65,
        ),
      ];
}
