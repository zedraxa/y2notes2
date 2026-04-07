import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:y2notes2/features/templates/data/builtin_templates.dart';
import 'package:y2notes2/features/templates/domain/entities/page_template.dart';
import 'package:y2notes2/features/templates/presentation/bloc/template_bloc.dart';
import 'package:y2notes2/features/templates/presentation/bloc/template_event.dart';
import 'package:y2notes2/features/templates/presentation/bloc/template_state.dart';
import 'package:y2notes2/features/templates/presentation/widgets/template_preview_card.dart';

/// Full-screen modal template picker with category tabs, search, preview cards.
class TemplatePicker extends StatefulWidget {
  const TemplatePicker({
    super.key,
    required this.onApply,
  });

  final void Function(NoteTemplate template) onApply;

  @override
  State<TemplatePicker> createState() => _TemplatePickerState();
}

class _TemplatePickerState extends State<TemplatePicker>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  static const _tabs = ['All', 'Study', 'Planning', 'Creative', 'Productivity', 'Special', 'Custom'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      context
          .read<TemplateBloc>()
          .add(TemplateCategoryChanged(_tabs[_tabController.index]));
    });
    _searchController.addListener(() {
      context
          .read<TemplateBloc>()
          .add(TemplateSearchQueryChanged(_searchController.text));
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<TemplateBloc, TemplateState>(
        builder: (context, state) {
          final templates = state.filteredTemplates;
          final recent = state.recentlyUsedTemplates;

          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.85,
            child: Column(
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        'Templates',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),
                // Search field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search templates...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      isDense: true,
                    ),
                  ),
                ),
                // Category tabs
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: _tabs.map((t) => Tab(text: t)).toList(),
                ),
                // Content
                Expanded(
                  child: state.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
                          padding: const EdgeInsets.all(12),
                          children: [
                            // Recently used section
                            if (recent.isNotEmpty &&
                                state.activeCategory == 'All' &&
                                state.searchQuery.isEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 8),
                                child: Text(
                                  'Recently Used',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              SizedBox(
                                height: 130,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: recent.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (_, i) => SizedBox(
                                    width: 200,
                                    child: TemplatePreviewCard(
                                      template: recent[i],
                                      isSelected: state.selectedTemplateId ==
                                          recent[i].id,
                                      onTap: () {
                                        context.read<TemplateBloc>().add(
                                            TemplateSelected(recent[i].id));
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            // Main grid
                            ...templates.map(
                              (t) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: TemplatePreviewCard(
                                  template: t,
                                  isSelected:
                                      state.selectedTemplateId == t.id,
                                  onTap: () {
                                    context
                                        .read<TemplateBloc>()
                                        .add(TemplateSelected(t.id));
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
                // Apply button
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: state.selectedTemplate != null
                          ? () {
                              final t = state.selectedTemplate!;
                              context
                                  .read<TemplateBloc>()
                                  .add(TemplateApplied(t.id));
                              widget.onApply(t);
                              Navigator.of(context).pop();
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Apply Template'),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
}
