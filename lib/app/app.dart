import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:biscuits/app/routes.dart';
import 'package:biscuits/app/theme/app_theme.dart';
import 'package:biscuits/core/services/settings_service.dart';
import 'package:biscuits/features/documents/data/document_repository.dart';
import 'package:biscuits/features/documents/presentation/bloc/document_bloc.dart';
import 'package:biscuits/features/library/data/library_repository.dart';
import 'package:biscuits/features/library/presentation/bloc/library_bloc.dart';

/// Root application widget.
class BiscuitsApp extends StatefulWidget {
  const BiscuitsApp({
    super.key,
    required this.settingsService,
    required this.documentRepository,
    required this.libraryRepository,
  });

  final SettingsService settingsService;
  final DocumentRepository documentRepository;
  final LibraryRepository libraryRepository;

  @override
  State<BiscuitsApp> createState() => _BiscuitsAppState();
}

class _BiscuitsAppState extends State<BiscuitsApp> {
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
            title: 'Biscuits',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
            routerConfig: _appRouter.router,
          ),
        ),
      );
}
