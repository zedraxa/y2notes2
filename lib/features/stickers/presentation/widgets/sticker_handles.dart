import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:biscuitse/features/stickers/presentation/bloc/sticker_bloc.dart';
import 'package:biscuitse/features/stickers/presentation/bloc/sticker_state.dart';

/// Widget that renders selection handles for the selected sticker.
/// The actual handle rendering logic lives in StickerRenderer.
class StickerHandlesOverlay extends StatelessWidget {
  const StickerHandlesOverlay({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<StickerBloc, StickerState>(
        buildWhen: (prev, curr) =>
            prev.selectedStickerId != curr.selectedStickerId ||
            prev.stickers != curr.stickers,
        builder: (context, state) {
          if (state.selectedSticker == null) return const SizedBox.shrink();
          return const SizedBox.expand();
        },
      );
}
