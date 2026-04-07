import 'package:go_router/go_router.dart';
import 'package:y2notes2/features/settings/presentation/effects_settings_page.dart';
import 'package:y2notes2/features/workspace/presentation/pages/workspace_page.dart';

/// Application router using GoRouter.
class AppRouter {
  late final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const WorkspacePage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const EffectsSettingsPage(),
        routes: [
          GoRoute(
            path: 'effects',
            builder: (context, state) =>
                const EffectsSettingsPage(showEffectsOnly: true),
          ),
        ],
      ),
    ],
  );
}
