import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:biscuits/features/collaboration/presentation/bloc/collaboration_bloc.dart';

/// Dialog that lets the user enter a room code to join an existing session.
class JoinDialog extends StatefulWidget {
  const JoinDialog({super.key});

  @override
  State<JoinDialog> createState() => _JoinDialogState();
}

class _JoinDialogState extends State<JoinDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final code = _controller.text.trim().toUpperCase();
    context.read<CollaborationBloc>().add(JoinSession(code));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Join a session'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter the 8-character room code shared by the host.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Room code',
                hintText: 'ABCD-1234',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (value) {
                final v = value?.trim().toUpperCase() ?? '';
                // Accept with or without dash.
                final cleaned = v.replaceAll('-', '');
                if (cleaned.length != 8) {
                  return 'Room code must be 8 characters';
                }
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Join'),
        ),
      ],
    );
  }
}
