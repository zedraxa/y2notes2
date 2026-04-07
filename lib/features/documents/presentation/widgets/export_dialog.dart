import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:y2notes2/features/documents/domain/models/export_options.dart';
import 'package:y2notes2/features/documents/presentation/bloc/document_bloc.dart';
import 'package:y2notes2/features/documents/presentation/bloc/document_event.dart';
import 'package:y2notes2/features/documents/presentation/bloc/document_state.dart';

/// Full-screen overlay that shows export/import progress with a cancel option.
class ExportProgressOverlay extends StatelessWidget {
  const ExportProgressOverlay({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<DocumentBloc, DocumentState>(
        buildWhen: (prev, curr) =>
            prev.isExporting != curr.isExporting ||
            prev.isImporting != curr.isImporting ||
            prev.exportProgress != curr.exportProgress ||
            prev.importProgress != curr.importProgress,
        builder: (context, state) {
          final isActive = state.isExporting || state.isImporting;
          if (!isActive) return const SizedBox.shrink();

          final label = state.isExporting ? 'Exporting…' : 'Importing…';
          final progress =
              state.isExporting ? state.exportProgress : state.importProgress;

          return Container(
            color: Colors.black54,
            child: Center(
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: progress > 0 ? progress : null,
                      ),
                      const SizedBox(height: 8),
                      if (progress > 0)
                        Text(
                          '${(progress * 100).round()}%',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
}

/// Dialog for configuring and triggering an export.
class ExportDialog extends StatefulWidget {
  const ExportDialog({super.key});

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  // ── Export format ──────────────────────────────────────────────────────────
  _ExportFormat _format = _ExportFormat.pdf;

  // ── PDF options ────────────────────────────────────────────────────────────
  PdfPageSize _pdfPageSize = PdfPageSize.a4;
  PdfOrientation _pdfOrientation = PdfOrientation.portrait;
  ExportQuality _pdfQuality = ExportQuality.high;
  bool _includeBackground = true;

  // ── Image options ──────────────────────────────────────────────────────────
  ImageExportFormat _imageFormat = ImageExportFormat.png;
  double _imageScale = 2.0;
  bool _transparentBg = false;
  bool _cropToContent = false;

  // ── Scope ──────────────────────────────────────────────────────────────────
  bool _exportAllPages = false;
  bool _shareAfterExport = false;

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _formatLabel(_ExportFormat f) => switch (f) {
        _ExportFormat.pdf => 'PDF',
        _ExportFormat.png => 'PNG',
        _ExportFormat.jpeg => 'JPEG',
      };

  void _doExport(BuildContext context) {
    final bloc = context.read<DocumentBloc>();
    Navigator.pop(context);

    switch (_format) {
      case _ExportFormat.pdf:
        final opts = PdfExportOptions(
          pageSize: _pdfPageSize,
          orientation: _pdfOrientation,
          quality: _pdfQuality,
          includeBackground: _includeBackground,
        );
        if (_shareAfterExport) {
          bloc.add(ShareCurrentPageAsPdf(options: opts));
        } else if (_exportAllPages) {
          bloc.add(ExportNotebookAsPdf(options: opts));
        } else {
          bloc.add(ExportCurrentPageAsPdf(options: opts));
        }
      case _ExportFormat.png:
        bloc.add(ExportCurrentPageAsImage(
          options: ImageExportOptions(
            format: ImageExportFormat.png,
            scale: _imageScale,
            transparentBackground: _transparentBg,
            cropToContent: _cropToContent,
          ),
        ));
      case _ExportFormat.jpeg:
        bloc.add(ExportCurrentPageAsImage(
          options: ImageExportOptions(
            format: ImageExportFormat.jpeg,
            scale: _imageScale,
            cropToContent: _cropToContent,
          ),
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Format selector.
            const Text('Format', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<_ExportFormat>(
              segments: _ExportFormat.values
                  .map((f) => ButtonSegment(
                        value: f,
                        label: Text(_formatLabel(f)),
                      ))
                  .toList(),
              selected: {_format},
              onSelectionChanged: (s) =>
                  setState(() => _format = s.first),
            ),
            const SizedBox(height: 16),

            // PDF-specific options.
            if (_format == _ExportFormat.pdf) ...[
              const Text('Page size',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButton<PdfPageSize>(
                value: _pdfPageSize,
                isExpanded: true,
                items: PdfPageSize.values
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.name.toUpperCase()),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _pdfPageSize = v ?? _pdfPageSize),
              ),
              const SizedBox(height: 8),
              const Text('Orientation',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              SegmentedButton<PdfOrientation>(
                segments: const [
                  ButtonSegment(
                    value: PdfOrientation.portrait,
                    icon: Icon(Icons.crop_portrait),
                    label: Text('Portrait'),
                  ),
                  ButtonSegment(
                    value: PdfOrientation.landscape,
                    icon: Icon(Icons.crop_landscape),
                    label: Text('Landscape'),
                  ),
                ],
                selected: {_pdfOrientation},
                onSelectionChanged: (s) =>
                    setState(() => _pdfOrientation = s.first),
              ),
              const SizedBox(height: 8),
              const Text('Quality',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              DropdownButton<ExportQuality>(
                value: _pdfQuality,
                isExpanded: true,
                items: ExportQuality.values
                    .map((q) => DropdownMenuItem(
                          value: q,
                          child: Text('${q.name[0].toUpperCase()}${q.name.substring(1)} (${q.dpi} DPI)'),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _pdfQuality = v ?? _pdfQuality),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Include background'),
                value: _includeBackground,
                onChanged: (v) => setState(() => _includeBackground = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Export all pages'),
                value: _exportAllPages,
                onChanged: (v) => setState(() => _exportAllPages = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Share after export'),
                value: _shareAfterExport,
                onChanged: (v) => setState(() => _shareAfterExport = v),
              ),
            ],

            // Image-specific options.
            if (_format != _ExportFormat.pdf) ...[
              const Text('Scale',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Slider(
                value: _imageScale,
                min: 1.0,
                max: 3.0,
                divisions: 2,
                label: '${_imageScale.round()}×',
                onChanged: (v) => setState(() => _imageScale = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Crop to content'),
                value: _cropToContent,
                onChanged: (v) => setState(() => _cropToContent = v),
              ),
              if (_format == _ExportFormat.png)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Transparent background'),
                  value: _transparentBg,
                  onChanged: (v) => setState(() => _transparentBg = v),
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () => _doExport(context),
          icon: const Icon(Icons.download_rounded),
          label: const Text('Export'),
        ),
      ],
    );
  }
}

enum _ExportFormat { pdf, png, jpeg }
