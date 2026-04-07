// Re-export the canonical shape and sticker element types so that the
// documents feature does not define its own incompatible stubs.
// Previously this file contained placeholder classes; now that PRs 3 & 4
// (Shape Recognition and Stickers) have been merged, we delegate to their
// authoritative implementations.
export 'package:biscuitse/features/shapes/domain/entities/shape_element.dart';
export 'package:biscuitse/features/stickers/domain/entities/sticker_element.dart';
