import 'package:y2notes2/features/canvas/domain/entities/tools/drawing_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/tool_category.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/ink/fountain_pen_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/ink/ballpoint_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/ink/felt_tip_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/ink/calligraphy_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/ink/brush_pen_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/paint/watercolor_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/paint/acrylic_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/paint/oil_paint_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/paint/gouache_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/paint/spray_paint_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/dry/pencil_hb_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/dry/pencil_2b_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/dry/charcoal_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/dry/pastel_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/dry/crayon_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/dry/chalk_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/dry/colored_pencil_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/glow/neon_pen_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/glow/glow_gel_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/glow/laser_pen_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/glow/uv_pen_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/glow/holographic_pen_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/glow/fire_pen_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/highlighter/classic_highlighter_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/highlighter/soft_highlighter_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/highlighter/neon_highlighter_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/highlighter/gradient_highlighter_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/highlighter/glowing_highlighter_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/highlighter/pastel_highlighter_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/utility/eraser_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/utility/lasso_tool.dart';
import 'package:y2notes2/features/canvas/domain/entities/tools/utility/text_tool.dart';

class ToolRegistry {
  static final Map<String, DrawingTool> _tools = {};

  static void registerAll() {
    final allTools = <DrawingTool>[
      FountainPenTool(),
      BallpointTool(),
      FeltTipTool(),
      CalligraphyTool(),
      BrushPenTool(),
      WatercolorTool(),
      AcrylicTool(),
      OilPaintTool(),
      GouacheTool(),
      SprayPaintTool(),
      PencilHbTool(),
      Pencil2bTool(),
      CharcoalTool(),
      PastelTool(),
      CrayonTool(),
      ChalkTool(),
      ColoredPencilTool(),
      NeonPenTool(),
      GlowGelTool(),
      LaserPenTool(),
      UvPenTool(),
      HolographicPenTool(),
      FirePenTool(),
      ClassicHighlighterTool(),
      SoftHighlighterTool(),
      NeonHighlighterTool(),
      GradientHighlighterTool(),
      GlowingHighlighterTool(),
      PastelHighlighterTool(),
      EraserTool(),
      LassoTool(),
      TextTool(),
    ];
    for (final tool in allTools) {
      _tools[tool.id] = tool;
    }
  }

  static DrawingTool? get(String id) => _tools[id];

  static List<DrawingTool> getAll() => _tools.values.toList();

  static List<DrawingTool> getByCategory(ToolCategory category) =>
      _tools.values.where((t) => t.category == category).toList();

  static bool isRegistered(String id) => _tools.containsKey(id);
}
