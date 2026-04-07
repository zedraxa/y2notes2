import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:y2notes2/features/documents/presentation/bloc/document_bloc.dart';
import 'package:y2notes2/features/documents/presentation/bloc/document_event.dart';
import 'package:y2notes2/features/documents/presentation/bloc/document_state.dart';
import 'package:y2notes2/features/documents/presentation/widgets/export_dialog.dart';
import 'package:y2notes2/features/documents/presentation/widgets/import_button.dart';
import 'package:y2notes2/features/documents/presentation/widgets/outline_panel.dart';
import 'package:y2notes2/features/documents/presentation/widgets/page_navigator.dart';

/// Full notebook view: the canvas (passed as [child]) surrounded by the
/// page navigator strip, outline panel, and export/import affordances.
class NotebookPageView extends StatelessWidget {
  const NotebookPageView({
    super.key,
    required this.child,
  });

  /// The canvas widget to render inside this view.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<DocumentBloc, DocumentState>(
      listenWhen: (prev, curr) =>
          prev.status != curr.status && curr.status == DocumentOperationStatus.error,
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
          context.read<DocumentBloc>().add(const ClearDocumentStatus());
        }
      },
      child: Stack(
        children: [
          // Main content: outline panel + canvas + page navigator.
          Row(
            children: [
              const OutlinePanel(),
              Expanded(
                child: Column(
                  children: [
                    Expanded(child: child),
                    const PageNavigator(),
                  ],
                ),
              ),
            ],
          ),
          // Progress overlay (shown during export/import).
          const ExportProgressOverlay(),
        ],
      ),
    );
  }
}

/// Toolbar buttons for export, import, and outline toggle.
class DocumentToolbarActions extends StatelessWidget {
  const DocumentToolbarActions({super.key});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Outline toggle button.
          BlocBuilder<DocumentBloc, DocumentState>(
            buildWhen: (prev, curr) =>
                prev.isOutlineOpen != curr.isOutlineOpen,
            builder: (context, state) => IconButton(
              icon: Icon(
                state.isOutlineOpen
                    ? Icons.menu_book_rounded
                    : Icons.menu_book_outlined,
              ),
              tooltip: state.isOutlineOpen ? 'Close outline' : 'Outline',
              iconSize: 20,
              onPressed: () => context
                  .read<DocumentBloc>()
                  .add(const ToggleOutlinePanel()),
            ),
          ),
          // Export button.
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: 'Export',
            iconSize: 20,
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => BlocProvider.value(
                value: context.read<DocumentBloc>(),
                child: const ExportDialog(),
              ),
            ),
          ),
          // Import button.
          BlocProvider.value(
            value: context.read<DocumentBloc>(),
            child: const ImportButton(),
          ),
        ],
      );
}
