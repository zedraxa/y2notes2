import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:biscuits/features/canvas/presentation/widgets/canvas_view.dart';
import 'package:biscuits/features/canvas/presentation/widgets/toolbar/floating_toolbar.dart';
import 'package:biscuits/features/documents/presentation/pages/notebook_page_view.dart';

/// Main canvas screen — the heart of the app.
///
/// Uses a full-screen body with the [FloatingToolbar] overlaid on top,
/// giving the user maximum canvas real estate. The toolbar is draggable,
/// collapsible, and auto-hides during active drawing.
class CanvasPage extends StatelessWidget {
  const CanvasPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(
          children: [
            // Full-screen canvas underneath.
            Positioned.fill(
              child: Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).padding.top),
                  const Expanded(
                    child: NotebookPageView(
                      child: CanvasView(),
                    ),
                  ),
                ],
              ),
            ),
            // Floating toolbar overlay.
            FloatingToolbar(
              onSettingsTap: () => context.push('/settings'),
            ),
          ],
        ),
      );
}
