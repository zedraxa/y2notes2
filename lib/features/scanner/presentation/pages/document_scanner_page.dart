import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:biscuits/features/scanner/domain/entities/scanned_document.dart';
import 'package:biscuits/features/scanner/presentation/bloc/scanner_bloc.dart';
import 'package:biscuits/features/scanner/presentation/bloc/scanner_event.dart';
import 'package:biscuits/features/scanner/presentation/bloc/scanner_state.dart';
import 'package:biscuits/features/scanner/presentation/widgets/edge_detection_overlay.dart';
import 'package:biscuits/features/scanner/presentation/widgets/scanner_filter_bar.dart';
import 'package:biscuits/features/scanner/presentation/widgets/scanned_page_thumbnails.dart';

/// Full-screen document scanner page.
///
/// Workflow:
/// 1. Capture/pick an image
/// 2. Auto-detect edges → show adjustable overlay
/// 3. Apply perspective correction + filter
/// 4. Review result (optionally run OCR)
/// 5. Confirm page & optionally scan more
/// 6. Complete session → return [ScanResult] via Navigator
class DocumentScannerPage extends StatelessWidget {
  const DocumentScannerPage({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocProvider(
        create: (_) => ScannerBloc()
          ..add(const ScannerSessionStarted()),
        child: const _ScannerView(),
      );
}

class _ScannerView extends StatelessWidget {
  const _ScannerView();

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<ScannerBloc, ScannerState>(
        listener: (context, state) {
          if (state.phase == ScannerPhase.completed &&
              state.scanResult != null) {
            Navigator.of(context)
                .pop(state.scanResult);
          }
          if (state.phase == ScannerPhase.error &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
              ),
            );
          }
        },
        builder: (context, state) => Scaffold(
          backgroundColor: Colors.black,
          appBar: _buildAppBar(context, state),
          body: _buildBody(context, state),
          bottomNavigationBar:
              _buildBottomBar(context, state),
        ),
      );

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ScannerState state,
  ) =>
      AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          _phaseTitle(state.phase),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            context.read<ScannerBloc>().add(
                  const ScannerSessionCancelled(),
                );
            Navigator.of(context).pop();
          },
        ),
        actions: [
          if (state.totalPages > 0 ||
              state.hasCurrentPage)
            TextButton(
              onPressed: () =>
                  _showCompleteDialog(context),
              child: Text(
                'Done (${state.totalPages + (state.hasCurrentPage ? 1 : 0)})',
                style:
                    const TextStyle(color: Colors.white),
              ),
            ),
        ],
      );

  Widget _buildBody(
    BuildContext context,
    ScannerState state,
  ) {
    switch (state.phase) {
      case ScannerPhase.idle:
      case ScannerPhase.capturing:
        return _buildCaptureView(context, state);
      case ScannerPhase.processing:
      case ScannerPhase.ocrInProgress:
        return _buildProcessingView(state);
      case ScannerPhase.adjusting:
        return _buildAdjustView(context, state);
      case ScannerPhase.reviewing:
        return _buildReviewView(context, state);
      case ScannerPhase.completed:
      case ScannerPhase.error:
        return _buildCaptureView(context, state);
    }
  }

  Widget _buildCaptureView(
    BuildContext context,
    ScannerState state,
  ) =>
      Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.document_scanner_outlined,
                    size: 80,
                    color: Colors.white.withValues(
                        alpha: 0.6),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Scan a Document',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Take a photo or pick an image from'
                    ' your gallery',
                    style: TextStyle(
                      color: Colors.white.withValues(
                          alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      _CaptureButton(
                        icon: Icons.camera_alt,
                        label: 'Camera',
                        onTap: () =>
                            _captureFromCamera(context),
                      ),
                      const SizedBox(width: 24),
                      _CaptureButton(
                        icon: Icons.photo_library,
                        label: 'Gallery',
                        onTap: () =>
                            _pickFromGallery(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (state.confirmedPages.isNotEmpty)
            ScannedPageThumbnails(
              pages: state.confirmedPages,
              onPageRemove: (i) =>
                  context.read<ScannerBloc>().add(
                        PageRemoved(pageIndex: i),
                      ),
            ),
        ],
      );

  Widget _buildProcessingView(ScannerState state) =>
      Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(
              state.phase == ScannerPhase.ocrInProgress
                  ? 'Running OCR…'
                  : 'Processing image…',
              style:
                  const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                value: state.processingProgress,
                backgroundColor: Colors.white24,
              ),
            ),
          ],
        ),
      );

  Widget _buildAdjustView(
    BuildContext context,
    ScannerState state,
  ) {
    final page = state.currentPage;
    if (page == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Show the original image underneath.
              if (page.processedImage != null)
                RawImage(
                  image: page.processedImage,
                  fit: BoxFit.contain,
                ),
              // Edge detection overlay.
              if (page.hasCorners)
                Positioned.fill(
                  child: EdgeDetectionOverlay(
                    corners: page.corners!,
                    imageSize: Size(
                      page.width,
                      page.height,
                    ),
                    onCornersChanged: (corners) {
                      context.read<ScannerBloc>().add(
                            CornersAdjusted(
                                corners: corners),
                          );
                    },
                  ),
                ),
            ],
          ),
        ),
        // Action buttons.
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceEvenly,
            children: [
              _ActionButton(
                icon: Icons.refresh,
                label: 'Retake',
                onTap: () {
                  context.read<ScannerBloc>().add(
                        const ScannerSessionStarted(),
                      );
                },
              ),
              _ActionButton(
                icon: Icons.crop_free,
                label: 'Apply Crop',
                isPrimary: true,
                onTap: () {
                  context.read<ScannerBloc>().add(
                        const ReprocessCurrentPage(),
                      );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewView(
    BuildContext context,
    ScannerState state,
  ) {
    final page = state.currentPage;
    if (page == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Expanded(
          child: page.processedImage != null
              ? RawImage(
                  image: page.processedImage,
                  fit: BoxFit.contain,
                )
              : const Center(
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.white54,
                    size: 64,
                  ),
                ),
        ),
        // Filter bar.
        ScannerFilterBar(
          selectedFilter: page.filter,
          onFilterChanged: (filter) {
            context.read<ScannerBloc>().add(
                  FilterChanged(filter: filter),
                );
          },
        ),
        const SizedBox(height: 8),
        // OCR result preview.
        if (page.hasOcrText)
          Container(
            margin: const EdgeInsets.symmetric(
                horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                  alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            constraints:
                const BoxConstraints(maxHeight: 100),
            child: SingleChildScrollView(
              child: Text(
                page.ocrText!,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        // Action buttons.
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceEvenly,
            children: [
              _ActionButton(
                icon: Icons.arrow_back,
                label: 'Re-crop',
                onTap: () {
                  // Re-process the original image to
                  // go back to the edge adjustment phase.
                  final current = context
                      .read<ScannerBloc>()
                      .state
                      .currentPage;
                  if (current != null) {
                    context.read<ScannerBloc>().add(
                          ImageCaptured(
                            imageBytes:
                                current.originalImage,
                          ),
                        );
                  }
                },
              ),
              _ActionButton(
                icon: Icons.text_fields,
                label: 'OCR',
                onTap: () {
                  context.read<ScannerBloc>().add(
                        const OcrRequested(),
                      );
                },
              ),
              _ActionButton(
                icon: Icons.check_circle,
                label: 'Confirm',
                isPrimary: true,
                onTap: () {
                  context.read<ScannerBloc>().add(
                        const PageConfirmed(),
                      );
                },
              ),
            ],
          ),
        ),
        if (state.confirmedPages.isNotEmpty)
          ScannedPageThumbnails(
            pages: state.confirmedPages,
            onPageRemove: (i) =>
                context.read<ScannerBloc>().add(
                      PageRemoved(pageIndex: i),
                    ),
          ),
      ],
    );
  }

  Widget? _buildBottomBar(
    BuildContext context,
    ScannerState state,
  ) {
    // Bottom bar only in capture mode with pages.
    if (state.phase != ScannerPhase.capturing) {
      return null;
    }
    if (state.confirmedPages.isEmpty) return null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: () =>
              _showCompleteDialog(context),
          icon: const Icon(Icons.check),
          label: Text(
            'Complete'
            ' (${state.confirmedPages.length} pages)',
          ),
        ),
      ),
    );
  }

  String _phaseTitle(ScannerPhase phase) {
    switch (phase) {
      case ScannerPhase.idle:
      case ScannerPhase.capturing:
        return 'Scan Document';
      case ScannerPhase.adjusting:
        return 'Adjust Edges';
      case ScannerPhase.processing:
        return 'Processing…';
      case ScannerPhase.reviewing:
        return 'Review';
      case ScannerPhase.ocrInProgress:
        return 'OCR Processing…';
      case ScannerPhase.completed:
        return 'Complete';
      case ScannerPhase.error:
        return 'Error';
    }
  }

  Future<void> _captureFromCamera(
    BuildContext context,
  ) async {
    // Use file_picker to select an image (camera
    // integration requires image_picker which can be
    // added later for native camera access).
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result == null ||
        result.files.isEmpty ||
        result.files.first.path == null) {
      return;
    }

    final bytes =
        await File(result.files.first.path!)
            .readAsBytes();
    if (context.mounted) {
      context.read<ScannerBloc>().add(
            ImageCaptured(imageBytes: bytes),
          );
    }
  }

  Future<void> _pickFromGallery(
    BuildContext context,
  ) async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result == null ||
        result.files.isEmpty ||
        result.files.first.path == null) {
      return;
    }

    final bytes =
        await File(result.files.first.path!)
            .readAsBytes();
    if (context.mounted) {
      context.read<ScannerBloc>().add(
            ImageCaptured(imageBytes: bytes),
          );
    }
  }

  Future<void> _showCompleteDialog(
    BuildContext context,
  ) async {
    final controller = TextEditingController(
      text: 'Scanned Document',
    );

    try {
      final title = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Save Scanned Document'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Document Title',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx)
                  .pop(controller.text),
              child: const Text('Save'),
            ),
          ],
        ),
      );

      if (title != null && context.mounted) {
        context.read<ScannerBloc>().add(
              ScannerSessionCompleted(title: title),
            );
      }
    } finally {
      controller.dispose();
    }
  }
}

class _CaptureButton extends StatelessWidget {
  const _CaptureButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) =>
      GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color:
                    Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white54,
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final color = isPrimary
        ? Theme.of(context).colorScheme.primary
        : Colors.white70;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isPrimary
                  ? color.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
