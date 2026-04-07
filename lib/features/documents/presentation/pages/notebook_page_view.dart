import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:biscuitse/features/documents/presentation/bloc/document_bloc.dart';
import 'package:biscuitse/features/documents/presentation/bloc/document_event.dart';
import 'package:biscuitse/features/documents/presentation/bloc/document_state.dart';
import 'package:biscuitse/features/documents/presentation/widgets/export_dialog.dart';
import 'package:biscuitse/features/documents/presentation/widgets/import_button.dart';
import 'package:biscuitse/features/documents/presentation/widgets/page_navigator.dart';

/// Full notebook view: the canvas (passed as [child]) surrounded by the
/// page navigator strip and export/import affordances.
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
          // Main canvas area.
          Column(
            children: [
              Expanded(child: child),
              const PageNavigator(),
            ],
          ),
          // Progress overlay (shown during export/import).
          const ExportProgressOverlay(),
        ],
      ),
    );
  }
}

/// Toolbar buttons for export and import actions.
class DocumentToolbarActions extends StatelessWidget {
  const DocumentToolbarActions({super.key});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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
