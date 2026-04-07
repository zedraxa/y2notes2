import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:biscuitse/app/routes.dart';
import 'package:biscuitse/app/theme/app_theme.dart';
import 'package:biscuitse/core/services/settings_service.dart';
import 'package:biscuitse/features/documents/data/document_repository.dart';
import 'package:biscuitse/features/documents/presentation/bloc/document_bloc.dart';
import 'package:biscuitse/features/library/data/library_repository.dart';
import 'package:biscuitse/features/library/presentation/bloc/library_bloc.dart';

/// Root application widget.
class BiscuitseApp extends StatefulWidget {
  const BiscuitseApp({
    super.key,
    required this.settingsService,
    required this.documentRepository,
    required this.libraryRepository,
  });

  final SettingsService settingsService;
  final DocumentRepository documentRepository;
  final LibraryRepository libraryRepository;

  @override
  State<BiscuitseApp> createState() => _BiscuitseAppState();
}

class _BiscuitseAppState extends State<BiscuitseApp> {
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _appRouter = AppRouter();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
        valueListenable: widget.settingsService.darkModeNotifier,
        builder: (context, isDark, _) => MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => DocumentBloc(
                repository: widget.documentRepository,
              ),
            ),
            BlocProvider(
              create: (_) => LibraryBloc(
                repository: widget.libraryRepository,
              ),
            ),
          ],
          child: MaterialApp.router(
            title: 'Biscuitsé',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
            routerConfig: _appRouter.router,
          ),
        ),
      );
}
