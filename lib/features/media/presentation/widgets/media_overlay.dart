import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:biscuits/features/media/presentation/bloc/media_bloc.dart';
import 'package:biscuits/features/media/presentation/bloc/media_state.dart';
import 'package:biscuits/features/media/presentation/widgets/media_player_widget.dart';

/// Overlay layer that renders all [MediaElement]s on the
/// canvas as draggable player widgets.
class MediaOverlay extends StatelessWidget {
  const MediaOverlay({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<MediaBloc, MediaState>(
        builder: (context, state) {
          if (state.elements.isEmpty) {
            return const SizedBox.shrink();
          }
          return Stack(
            children: state.elements.map((element) {
              return Positioned(
                left: element.position.dx,
                top: element.position.dy,
                child: MediaPlayerWidget(
                  element: element,
                ),
              );
            }).toList(),
          );
        },
      );
}
