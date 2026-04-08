import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:biscuits/features/canvas/presentation/widgets/canvas_view.dart';
import 'package:biscuits/features/canvas/presentation/widgets/toolbar/main_toolbar.dart';
import 'package:biscuits/features/documents/presentation/pages/notebook_page_view.dart';
import 'package:biscuits/shared/widgets/app_scaffold.dart';

/// Main canvas screen — the heart of the app.
class CanvasPage extends StatelessWidget {
  const CanvasPage({super.key});

  @override
  Widget build(BuildContext context) => AppScaffold(
        toolbar: MainToolbar(
          onSettingsTap: () => context.push('/settings'),
        ),
        body: const NotebookPageView(
          child: CanvasView(),
        ),
      );
}
