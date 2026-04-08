import 'package:flutter/material.dart';
import 'package:biscuits/features/scanner/domain/entities/scanned_document.dart';

/// Thumbnail strip showing confirmed scanned pages with
/// delete and reorder capabilities.
class ScannedPageThumbnails extends StatelessWidget {
  const ScannedPageThumbnails({
    required this.pages,
    this.selectedIndex,
    this.onPageTap,
    this.onPageRemove,
    super.key,
  });

  final List<ScannedPage> pages;
  final int? selectedIndex;
  final ValueChanged<int>? onPageTap;
  final ValueChanged<int>? onPageRemove;

  @override
  Widget build(BuildContext context) {
    if (pages.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(horizontal: 12),
        itemCount: pages.length,
        itemBuilder: (context, index) {
          final page = pages[index];
          final isSelected = index == selectedIndex;

          return GestureDetector(
            onTap: () => onPageTap?.call(index),
            child: Container(
              width: 60,
              margin: const EdgeInsets.symmetric(
                  horizontal: 4),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context)
                          .colorScheme
                          .primary
                      : Colors.grey.shade300,
                  width: isSelected ? 2.5 : 1.0,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(5),
                    child: page.processedImage != null
                        ? RawImage(
                            image: page.processedImage,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.document_scanner,
                              size: 24,
                            ),
                          ),
                  ),
                  // Page number badge.
                  Positioned(
                    left: 2,
                    bottom: 2,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius:
                            BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Delete button.
                  if (onPageRemove != null)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: GestureDetector(
                        onTap: () =>
                            onPageRemove?.call(index),
                        child: Container(
                          padding:
                              const EdgeInsets.all(2),
                          decoration:
                              const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
