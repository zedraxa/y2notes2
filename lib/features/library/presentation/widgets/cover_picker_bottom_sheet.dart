import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:biscuits/features/documents/domain/entities/notebook.dart';
import 'package:biscuits/features/documents/presentation/bloc/document_bloc.dart';
import 'package:biscuits/features/documents/presentation/bloc/document_event.dart';
import 'package:biscuits/features/library/domain/entities/library_item.dart';
import 'package:biscuits/features/library/presentation/bloc/library_bloc.dart';
import 'package:biscuits/features/library/presentation/bloc/library_event.dart';
import 'package:biscuits/features/library/presentation/widgets/notebook_cover_widget.dart';

/// Bottom sheet that lets users customise the cover color and material of a
/// notebook.
///
/// Dispatches [SetNotebookCover] to [LibraryBloc] to persist cover data in the
/// library item, and optionally [ChangeNotebookCover] to [DocumentBloc] if a
/// notebook is currently open.
class CoverPickerBottomSheet extends StatefulWidget {
  const CoverPickerBottomSheet({
    super.key,
    required this.item,
  });

  final LibraryItem item;

  /// Show the bottom sheet for [item].
  static Future<void> show(BuildContext context, LibraryItem item) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<LibraryBloc>()),
          BlocProvider.value(value: context.read<DocumentBloc>()),
        ],
        child: CoverPickerBottomSheet(item: item),
      ),
    );
  }

  @override
  State<CoverPickerBottomSheet> createState() => _CoverPickerBottomSheetState();
}

class _CoverPickerBottomSheetState extends State<CoverPickerBottomSheet> {
  late Color _selectedColor;
  late CoverMaterial _selectedMaterial;
  late CoverPattern _selectedPattern;
  late CoverEmblem _selectedEmblem;

  // ── Color presets ─────────────────────────────────────────────────────────

  static const _colors = [
    // Blues
    Color(0xFF2563EB),
    Color(0xFF1D4ED8),
    Color(0xFF3B82F6),
    Color(0xFF0EA5E9),
    Color(0xFF0891B2),
    // Greens
    Color(0xFF16A34A),
    Color(0xFF15803D),
    Color(0xFF0F766E),
    Color(0xFF84CC16),
    Color(0xFF65A30D),
    // Reds / Pinks
    Color(0xFFDC2626),
    Color(0xFFB91C1C),
    Color(0xFFE11D48),
    Color(0xFFF97316),
    Color(0xFFEA580C),
    // Purples
    Color(0xFF7C3AED),
    Color(0xFF6D28D9),
    Color(0xFF4338CA),
    Color(0xFF9333EA),
    Color(0xFFC026D3),
    // Neutrals
    Color(0xFF1E293B),
    Color(0xFF374151),
    Color(0xFF6B7280),
    Color(0xFFD97706),
    Color(0xFFFFFBEB),
  ];

  @override
  void initState() {
    super.initState();
    final raw = widget.item.coverColor;
    _selectedColor = raw != null ? Color(raw) : NotebookCoverConfig.azure.color;

    final matName = widget.item.coverMaterial;
    _selectedMaterial = matName != null
        ? CoverMaterial.values.byName(matName)
        : CoverMaterial.matte;

    final patName = widget.item.coverPattern;
    _selectedPattern = patName != null
        ? CoverPattern.values.byName(patName)
        : CoverPattern.none;

    final embName = widget.item.coverEmblem;
    _selectedEmblem = embName != null
        ? CoverEmblem.values.byName(embName)
        : CoverEmblem.none;
  }

  void _apply() {
    final cover = NotebookCoverConfig(
      color: _selectedColor,
      material: _selectedMaterial,
      pattern: _selectedPattern,
      emblem: _selectedEmblem,
    );
    context.read<LibraryBloc>().add(SetNotebookCover(
          itemId: widget.item.id,
          coverColor: _selectedColor.value,
          coverMaterial: _selectedMaterial.name,
          coverPattern: _selectedPattern.name,
          coverEmblem: _selectedEmblem.name,
        ));
    // If the notebook is currently open, update DocumentBloc too.
    final docBloc = context.read<DocumentBloc>();
    if (docBloc.state.notebook != null) {
      docBloc.add(ChangeNotebookCover(cover: cover));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        );

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Customise Cover',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 16),
              // ── Live preview ────────────────────────────────────────────────
              Center(
                child: NotebookCoverWidget(
                  color: _selectedColor,
                  material: _selectedMaterial,
                  pattern: _selectedPattern,
                  emblem: _selectedEmblem,
                  title: widget.item.name,
                  width: 100,
                  height: 136,
                ),
              ),
              const SizedBox(height: 20),
              // ── Color picker ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('COLOUR', style: labelStyle),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _colors.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final c = _colors[index];
                    final isSelected = c.value == _selectedColor.value;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = c),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2.5,
                                )
                              : Border.all(
                                  color: Colors.transparent,
                                  width: 2.5,
                                ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: c.withOpacity(0.5),
                                blurRadius: 6,
                              ),
                          ],
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              // ── Material picker ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('MATERIAL', style: labelStyle),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: CoverMaterial.values.map((m) {
                    return ChoiceChip(
                      label: Text(_materialLabel(m)),
                      selected: _selectedMaterial == m,
                      onSelected: (_) => setState(() => _selectedMaterial = m),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              // ── Pattern picker ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('PATTERN', style: labelStyle),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: CoverPattern.values.map((p) {
                    return ChoiceChip(
                      label: Text(_patternLabel(p)),
                      selected: _selectedPattern == p,
                      onSelected: (_) => setState(() => _selectedPattern = p),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              // ── Emblem picker ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('EMBLEM', style: labelStyle),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: CoverEmblem.values.map((e) {
                    return ChoiceChip(
                      avatar: _emblemIcon(e),
                      label: Text(_emblemLabel(e)),
                      selected: _selectedEmblem == e,
                      onSelected: (_) => setState(() => _selectedEmblem = e),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              // ── Actions ─────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: FilledButton(
                  onPressed: _apply,
                  child: const Text('Apply'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _materialLabel(CoverMaterial m) {
    switch (m) {
      case CoverMaterial.matte:
        return 'Matte';
      case CoverMaterial.leather:
        return 'Leather';
      case CoverMaterial.canvas:
        return 'Canvas';
      case CoverMaterial.linen:
        return 'Linen';
      case CoverMaterial.kraft:
        return 'Kraft';
      case CoverMaterial.glossy:
        return 'Glossy';
    }
  }

  String _patternLabel(CoverPattern p) {
    switch (p) {
      case CoverPattern.none:
        return 'None';
      case CoverPattern.stripes:
        return 'Stripes';
      case CoverPattern.dots:
        return 'Dots';
      case CoverPattern.chevron:
        return 'Chevron';
      case CoverPattern.diamond:
        return 'Diamond';
      case CoverPattern.plaid:
        return 'Plaid';
      case CoverPattern.moroccan:
        return 'Moroccan';
      case CoverPattern.herringbone:
        return 'Herringbone';
    }
  }

  String _emblemLabel(CoverEmblem e) {
    switch (e) {
      case CoverEmblem.none:
        return 'None';
      case CoverEmblem.star:
        return 'Star';
      case CoverEmblem.heart:
        return 'Heart';
      case CoverEmblem.leaf:
        return 'Leaf';
      case CoverEmblem.crown:
        return 'Crown';
      case CoverEmblem.compass:
        return 'Compass';
      case CoverEmblem.feather:
        return 'Feather';
      case CoverEmblem.moon:
        return 'Moon';
    }
  }

  Widget? _emblemIcon(CoverEmblem e) {
    const size = 18.0;
    switch (e) {
      case CoverEmblem.none:
        return const Icon(Icons.block, size: size);
      case CoverEmblem.star:
        return const Icon(Icons.star_outline, size: size);
      case CoverEmblem.heart:
        return const Icon(Icons.favorite_outline, size: size);
      case CoverEmblem.leaf:
        return const Icon(Icons.eco_outlined, size: size);
      case CoverEmblem.crown:
        return const Icon(Icons.shield_outlined, size: size);
      case CoverEmblem.compass:
        return const Icon(Icons.explore_outlined, size: size);
      case CoverEmblem.feather:
        return const Icon(Icons.edit_outlined, size: size);
      case CoverEmblem.moon:
        return const Icon(Icons.dark_mode_outlined, size: size);
    }
  }
}
