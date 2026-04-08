import 'package:flutter/material.dart';
import 'package:biscuits/features/collaboration/domain/entities/permission.dart';

/// Small badge that displays a participant's [PermissionLevel].
class PermissionBadge extends StatelessWidget {
  const PermissionBadge({super.key, required this.level});

  final PermissionLevel level;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (level) {
      PermissionLevel.owner => ('Owner', Colors.amber.shade700),
      PermissionLevel.editor => ('Editor', Colors.blue.shade600),
      PermissionLevel.viewer => ('Viewer', Colors.grey.shade600),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
