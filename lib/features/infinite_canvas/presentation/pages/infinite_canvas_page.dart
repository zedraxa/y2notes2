import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/infinite_canvas_bloc.dart';
import '../bloc/infinite_canvas_event.dart';
import '../bloc/infinite_canvas_state.dart';
import '../widgets/infinite_canvas_toolbar.dart';
import '../widgets/infinite_canvas_view.dart';

/// Full-screen page for an infinite canvas session.
///
/// Provides [InfiniteCanvasBloc] if not already injected from above.
class InfiniteCanvasPage extends StatelessWidget {
  /// Optional document id.  If null a blank canvas is shown.
  const InfiniteCanvasPage({super.key, this.canvasId});

  final String? canvasId;

  @override
  Widget build(BuildContext context) {
    // Wrap in a BlocProvider so this page can be navigated to standalone.
    return BlocProvider<InfiniteCanvasBloc>(
      create: (_) => InfiniteCanvasBloc(),
      child: const _InfiniteCanvasScaffold(),
    );
  }
}

class _InfiniteCanvasScaffold extends StatelessWidget {
  const _InfiniteCanvasScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Top toolbar.
          const InfiniteCanvasToolbar(),
          // Canvas surface.
          const Expanded(
            child: InfiniteCanvasView(),
          ),
        ],
      ),
    );
  }
}
