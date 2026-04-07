import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:y2notes2/features/documents/presentation/bloc/document_bloc.dart';
import 'package:y2notes2/features/documents/presentation/bloc/document_event.dart';

/// A compact toolbar button that triggers the file picker for PDF or image
/// import.
class ImportButton extends StatelessWidget {
  const ImportButton({super.key});

  @override
  Widget build(BuildContext context) => PopupMenuButton<_ImportType>(
        icon: const Icon(Icons.file_upload_outlined),
        tooltip: 'Import',
        itemBuilder: (_) => const [
          PopupMenuItem(
            value: _ImportType.pdf,
            child: ListTile(
              leading: Icon(Icons.picture_as_pdf_outlined),
              title: Text('Import PDF'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          PopupMenuItem(
            value: _ImportType.image,
            child: ListTile(
              leading: Icon(Icons.image_outlined),
              title: Text('Import Image'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
        onSelected: (type) {
          final bloc = context.read<DocumentBloc>();
          switch (type) {
            case _ImportType.pdf:
              bloc.add(const ImportPdf());
            case _ImportType.image:
              bloc.add(const ImportImage());
          }
        },
      );
}

enum _ImportType { pdf, image }
