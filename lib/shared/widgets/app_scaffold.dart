import 'package:flutter/material.dart';
import 'package:y2notes2/core/constants/app_constants.dart';

/// Base scaffold used by all full-screen pages.
///
/// Provides consistent layout with the thin top toolbar, optional FAB,
/// and a scrollable/expandable body area.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.toolbar,
    this.floatingActionButton,
    this.backgroundColor,
  });

  final Widget body;
  final Widget? toolbar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: backgroundColor ??
            Theme.of(context).scaffoldBackgroundColor,
        floatingActionButton: floatingActionButton,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // System status bar safe area
            SizedBox(height: MediaQuery.of(context).padding.top),
            if (toolbar != null) toolbar!,
            Expanded(child: body),
          ],
        ),
      );
}
