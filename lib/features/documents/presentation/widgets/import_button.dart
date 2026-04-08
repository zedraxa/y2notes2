import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:y2notes2/features/documents/domain/models/import_options.dart';
import 'package:y2notes2/features/documents/presentation/bloc/document_bloc.dart';
import 'package:y2notes2/features/documents/presentation/bloc/document_event.dart';
import 'package:y2notes2/features/documents/presentation/bloc/document_state.dart';
import 'package:y2notes2/features/scanner/domain/entities/scanned_document.dart';
import 'package:y2notes2/features/scanner/presentation/pages/document_scanner_page.dart';

/// A toolbar button that triggers PDF or image imports. Shows a popup menu
/// with options for scanning, PDF, single image, and multiple images. Displays an
/// inline progress indicator while an import is in progress.
class ImportButton extends StatelessWidget {
  const ImportButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DocumentBloc, DocumentState>(
      buildWhen: (prev, curr) =>
          prev.isImporting != curr.isImporting ||
          prev.importProgress != curr.importProgress,
      builder: (context, state) {
        if (state.isImporting) {
          return _ImportProgressIndicator(progress: state.importProgress);
        }

        return PopupMenuButton<_ImportType>(
          icon: const Icon(Icons.file_upload_outlined),
          tooltip: 'Import',
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: _ImportType.scan,
              child: ListTile(
                leading: Icon(Icons.document_scanner_outlined),
                title: Text('Scan Document'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: _ImportType.pdf,
              child: ListTile(
                leading: Icon(Icons.picture_as_pdf_outlined),
                title: Text('Import PDF'),
                subtitle: Text('Import as new notebook'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: _ImportType.pdfAppend,
              child: ListTile(
                leading: Icon(Icons.post_add_outlined),
                title: Text('Import PDF Pages'),
                subtitle: Text('Append to current notebook'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: _ImportType.image,
              child: ListTile(
                leading: Icon(Icons.image_outlined),
                title: Text('Import Image'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: _ImportType.multipleImages,
              child: ListTile(
                leading: Icon(Icons.photo_library_outlined),
                title: Text('Import Multiple Images'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
          onSelected: (type) => _onImportSelected(context, type),
        );
      },
    );
  }

  void _onImportSelected(BuildContext context, _ImportType type) {
    final bloc = context.read<DocumentBloc>();
    final hasNotebook = bloc.state.hasNotebook;

    switch (type) {
      case _ImportType.pdf:
        bloc.add(const ImportPdf(
          options: ImportOptions(mode: ImportMode.newNotebook),
        ));
      case _ImportType.pdfAppend:
        if (hasNotebook) {
          bloc.add(const ImportPdf(
            options: ImportOptions(mode: ImportMode.appendToCurrentNotebook),
          ));
        } else {
          // No notebook open — fall back to new notebook mode.
          bloc.add(const ImportPdf(
            options: ImportOptions(mode: ImportMode.newNotebook),
          ));
        }
      case _ImportType.image:
        bloc.add(ImportImage(
          options: ImportOptions(
            mode: hasNotebook
                ? ImportMode.appendToCurrentNotebook
                : ImportMode.newNotebook,
          ),
        ));
      case _ImportType.multipleImages:
        bloc.add(ImportMultipleImages(
          options: ImportOptions(
            mode: hasNotebook
                ? ImportMode.appendToCurrentNotebook
                : ImportMode.newNotebook,
          ),
        ));
      case _ImportType.scan:
        _openScanner(context, bloc);
    }
  }

  Future<void> _openScanner(
    BuildContext context,
    DocumentBloc bloc,
  ) async {
    final result = await Navigator.of(context).push<ScanResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const DocumentScannerPage(),
      ),
    );

    if (result != null) {
      bloc.add(ImportScannedDocument(scanResult: result));
    }
  }
}

/// Compact progress indicator shown while an import is in progress.
class _ImportProgressIndicator extends StatelessWidget {
  const _ImportProgressIndicator({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: progress > 0 ? progress : null,
              strokeWidth: 2.5,
            ),
            Text(
              progress > 0 ? '${(progress * 100).round()}%' : '',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 9,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ImportType { scan, pdf, pdfAppend, image, multipleImages }
