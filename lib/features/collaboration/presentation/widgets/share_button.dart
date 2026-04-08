import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:biscuits/features/collaboration/presentation/bloc/collaboration_bloc.dart';
import 'package:biscuits/features/collaboration/presentation/widgets/join_dialog.dart';
import 'package:biscuits/features/collaboration/presentation/widgets/participants_panel.dart';

/// Toolbar button that opens the share / collaboration menu.
///
/// Shows the current room code and a copy-link button when already in a
/// session. Otherwise offers "Start" and "Join" options.
class ShareButton extends StatelessWidget {
  const ShareButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CollaborationBloc, CollaborationState>(
      builder: (context, state) {
        if (state.isInSession) {
          return _ActiveSessionButton(state: state);
        }
        return _StartJoinButton();
      },
    );
  }
}

class _StartJoinButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_ShareAction>(
      tooltip: 'Collaborate',
      icon: const Icon(Icons.people_outline),
      onSelected: (action) {
        switch (action) {
          case _ShareAction.start:
            context.read<CollaborationBloc>().add(const StartSession());
          case _ShareAction.join:
            showDialog<void>(
              context: context,
              builder: (_) => BlocProvider.value(
                value: context.read<CollaborationBloc>(),
                child: const JoinDialog(),
              ),
            );
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: _ShareAction.start,
          child: ListTile(
            leading: Icon(Icons.add_circle_outline),
            title: Text('Start collaboration'),
            dense: true,
          ),
        ),
        PopupMenuItem(
          value: _ShareAction.join,
          child: ListTile(
            leading: Icon(Icons.login_rounded),
            title: Text('Join session'),
            dense: true,
          ),
        ),
      ],
    );
  }
}

class _ActiveSessionButton extends StatelessWidget {
  const _ActiveSessionButton({required this.state});

  final CollaborationState state;

  @override
  Widget build(BuildContext context) {
    final code = state.roomCode ?? '';
    return PopupMenuButton<_SessionAction>(
      tooltip: 'Session: $code',
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.people),
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
      onSelected: (action) {
        switch (action) {
          case _SessionAction.copyLink:
            final url = state.shareUrl ?? '';
            Clipboard.setData(ClipboardData(text: url));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Link copied: $url'),
                duration: const Duration(seconds: 2),
              ),
            );
          case _SessionAction.participants:
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => BlocProvider.value(
                value: context.read<CollaborationBloc>(),
                child: const _ParticipantsSheet(),
              ),
            );
          case _SessionAction.leave:
            context.read<CollaborationBloc>().add(const LeaveSession());
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem<_SessionAction>(
          enabled: false,
          child: ListTile(
            leading: const Icon(Icons.tag),
            title: Text('Room: $code'),
            dense: true,
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: _SessionAction.copyLink,
          child: ListTile(
            leading: Icon(Icons.copy_outlined),
            title: Text('Copy invite link'),
            dense: true,
          ),
        ),
        const PopupMenuItem(
          value: _SessionAction.participants,
          child: ListTile(
            leading: Icon(Icons.people_outline),
            title: Text('Participants'),
            dense: true,
          ),
        ),
        const PopupMenuItem(
          value: _SessionAction.leave,
          child: ListTile(
            leading: Icon(Icons.logout_rounded),
            title: Text('Leave session'),
            dense: true,
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet wrapper around [ParticipantsPanel].
class _ParticipantsSheet extends StatelessWidget {
  const _ParticipantsSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      builder: (_, scrollController) => Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.zero,
              children: const [ParticipantsPanel()],
            ),
          ),
        ],
      ),
    );
  }
}

enum _ShareAction { start, join }
enum _SessionAction { copyLink, participants, leave }
