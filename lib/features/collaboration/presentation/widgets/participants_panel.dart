import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:y2notes2/features/collaboration/domain/entities/participant.dart';
import 'package:y2notes2/features/collaboration/presentation/bloc/collaboration_bloc.dart';
import 'package:y2notes2/features/collaboration/presentation/widgets/remote_cursors.dart';
import 'package:y2notes2/features/collaboration/presentation/widgets/permission_badge.dart';

/// Side panel showing all current session participants with their status.
class ParticipantsPanel extends StatelessWidget {
  const ParticipantsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CollaborationBloc, CollaborationState>(
      builder: (context, state) {
        final participants = state.participants.values.toList();

        return Container(
          width: 220,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              left: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Row(
                  children: [
                    const Icon(Icons.people, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Participants (${participants.length})',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: participants.length,
                  itemBuilder: (ctx, i) =>
                      _ParticipantTile(participant: participants[i]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({required this.participant});

  final Participant participant;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Stack(
        children: [
          ParticipantAvatar(participant: participant, radius: 14),
          Positioned(
            right: 0,
            bottom: 0,
            child: _StatusDot(status: participant.status),
          ),
        ],
      ),
      title: Text(
        participant.displayName,
        style: const TextStyle(fontSize: 13),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: PermissionBadge(level: participant.permission),
    );
  }
}

/// Small colored dot indicating online/idle/disconnected status.
class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});

  final PresenceStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      PresenceStatus.active => Colors.green,
      PresenceStatus.idle => Colors.amber,
      PresenceStatus.disconnected => Colors.grey,
    };
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.surface,
          width: 1.2,
        ),
      ),
    );
  }
}
