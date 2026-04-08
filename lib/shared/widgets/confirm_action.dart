import 'package:flutter/material.dart';
import 'package:biscuits/shared/widgets/apple_sheet.dart';

/// Apple-style confirmation dialog for destructive or important actions.
///
/// Wraps [showAppleDialog] with sensible defaults for confirming irreversible
/// operations like deleting notebooks, emptying trash, or removing data.
///
/// Returns `true` if the user confirmed, `false` or `null` otherwise.
///
/// Usage:
/// ```dart
/// final confirmed = await confirmAction(
///   context: context,
///   title: 'Delete Notebook?',
///   message: 'This action cannot be undone.',
///   confirmLabel: 'Delete',
///   isDestructive: true,
/// );
/// if (confirmed == true) {
///   // proceed with deletion
/// }
/// ```
Future<bool?> confirmAction({
  required BuildContext context,
  required String title,
  String? message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool isDestructive = false,
}) {
  return showAppleDialog<bool>(
    context: context,
    title: title,
    content: message,
    barrierDismissible: true,
    actions: [
      AppleDialogAction(
        label: cancelLabel,
        result: false,
      ),
      AppleDialogAction(
        label: confirmLabel,
        isDefault: !isDestructive,
        isDestructive: isDestructive,
        result: true,
      ),
    ],
  );
}
