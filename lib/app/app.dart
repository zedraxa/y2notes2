import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:y2notes2/app/routes.dart';
import 'package:y2notes2/app/theme/app_theme.dart';
import 'package:y2notes2/core/services/settings_service.dart';
import 'package:y2notes2/features/documents/data/document_repository.dart';
import 'package:y2notes2/features/documents/presentation/bloc/document_bloc.dart';

/// Root application widget.
class Y2NotesApp extends StatefulWidget {
  const Y2NotesApp({
    super.key,
    required this.settingsService,
    required this.documentRepository,
  });

  final SettingsService settingsService;
  final DocumentRepository documentRepository;

  @override
  State<Y2NotesApp> createState() => _Y2NotesAppState();
}

class _Y2NotesAppState extends State<Y2NotesApp> {
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _appRouter = AppRouter();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
        valueListenable: widget.settingsService.darkModeNotifier,
        builder: (context, isDark, _) => BlocProvider(
          create: (_) => DocumentBloc(
            repository: widget.documentRepository,
          ),
          child: MaterialApp.router(
            title: 'Y2Notes',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
            routerConfig: _appRouter.router,
          ),
        ),
      );
}
