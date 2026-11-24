import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/network/api_client.dart';
import 'core/storage/session_store.dart'
    show SessionStore;
import 'core/storage/local_store.dart'
    show LocalStore;
import 'features/auth/data/auth_repository.dart'
    show AuthRepository;
import 'features/auth/presentation/auth_controller.dart'
    show AuthController;
import 'features/scanner/data/scan_repository.dart'
    show ScanRepository;
import 'features/community/data/forum_repository.dart'
    show ForumRepository;
import 'features/community/presentation/community_controller.dart'
    show CommunityController;

class KawangiziApp extends StatefulWidget {
  const KawangiziApp({super.key});

  @override
  State<KawangiziApp> createState() => _KawangiziAppState();
}

class _AppServices {
  final ApiClient api;
  final LocalStore localStore;
  final AuthController authController;
  final CommunityController communityController;
  final ScanRepository scanRepository;
  final GoRouter router;

  _AppServices({
    required this.api,
    required this.localStore,
    required this.authController,
    required this.communityController,
    required this.scanRepository,
    required this.router,
  });
}

class _KawangiziAppState extends State<KawangiziApp> {
  late final Future<_AppServices> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initServices();
  }

  Future<_AppServices> _initServices() async {
    final api = await ApiClient.create();
    final sessionStore = SessionStore();
    final localStore = LocalStore();
    final authRepository = AuthRepository(api: api, sessionStore: sessionStore);
    final scanRepository = ScanRepository(api: api);
    final forumRepository = ForumRepository(api: api, localStore: localStore);
    final authController = AuthController(authRepository: authRepository);
    final communityController = CommunityController(
      forumRepository: forumRepository,
      localStore: localStore,
    );
    final router = createRouter(authController);

    return _AppServices(
      api: api,
      localStore: localStore,
      authController: authController,
      communityController: communityController,
      scanRepository: scanRepository,
      router: router,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AppServices>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done || !snapshot.hasData) {
          if (snapshot.hasError) {
            return MaterialApp(
              theme: AppTheme.light,
              debugShowCheckedModeBanner: false,
              home: Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Gagal menginisialisasi aplikasi:\n${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
          return MaterialApp(
            theme: AppTheme.light,
            debugShowCheckedModeBanner: false,
            home: const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF123624)),
              ),
            ),
          );
        }

        final s = snapshot.data!;
        return MultiProvider(
          providers: [
            Provider<ApiClient>.value(value: s.api),
            Provider<LocalStore>.value(value: s.localStore),
            ChangeNotifierProvider<AuthController>.value(value: s.authController),
            ChangeNotifierProvider<CommunityController>.value(value: s.communityController),
            Provider<ScanRepository>.value(value: s.scanRepository),
          ],
          child: MaterialApp.router(
            title: 'KawanGizi',
            theme: AppTheme.light,
            debugShowCheckedModeBanner: false,
            routerConfig: s.router,
          ),
        );
      },
    );
  }
}
