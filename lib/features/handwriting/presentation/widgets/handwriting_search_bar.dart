import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:y2notes2/features/handwriting/presentation/bloc/handwriting_bloc.dart';
import 'package:y2notes2/features/handwriting/presentation/bloc/handwriting_event.dart';
import 'package:y2notes2/features/handwriting/presentation/bloc/handwriting_state.dart';
import 'package:y2notes2/features/handwriting/domain/models/search_match.dart';

/// Expandable search bar for searching recognized handwriting text.
class HandwritingSearchBar extends StatefulWidget {
  const HandwritingSearchBar({super.key, this.onMatchSelected});

  final void Function(SearchMatch match)? onMatchSelected;

  @override
  State<HandwritingSearchBar> createState() => _HandwritingSearchBarState();
}

class _HandwritingSearchBarState extends State<HandwritingSearchBar> {
  final _controller = TextEditingController();
  bool _isExpanded = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search input row
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 40,
          width: _isExpanded ? 260 : 40,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  _isExpanded ? Icons.close : Icons.search,
                  size: 18,
                ),
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 40, minHeight: 40),
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                    if (!_isExpanded) {
                      _controller.clear();
                      context.read<HandwritingBloc>().add(
                            const SearchQueryChanged(''),
                          );
                    }
                  });
                },
              ),
              if (_isExpanded)
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Search handwriting…',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 8),
                    ),
                    onChanged: (query) {
                      context.read<HandwritingBloc>().add(
                            SearchQueryChanged(query),
                          );
                    },
                  ),
                ),
            ],
          ),
        ),
        // Results
        if (_isExpanded)
          BlocBuilder<HandwritingBloc, HandwritingState>(
            buildWhen: (prev, curr) =>
                prev.searchMatches != curr.searchMatches,
            builder: (context, state) {
              if (state.searchMatches.isEmpty &&
                  state.searchQuery != null &&
                  state.searchQuery!.isNotEmpty) {
                return Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'No matches found',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              }
              if (state.searchMatches.isEmpty) {
                return const SizedBox.shrink();
              }
              return Container(
                margin: const EdgeInsets.only(top: 4),
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                    )
                  ],
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: state.searchMatches.length,
                  itemBuilder: (context, index) {
                    final match = state.searchMatches[index];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.search, size: 16),
                      title: Text(
                        match.matchedText,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      subtitle: match.contextSnippet.isNotEmpty
                          ? Text(
                              match.contextSnippet,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11),
                            )
                          : null,
                      onTap: () => widget.onMatchSelected?.call(match),
                    );
                  },
                ),
              );
            },
          ),
      ],
    );
  }
}
