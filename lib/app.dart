import 'package:flutter/material.dart';
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

class KawangiziApp extends StatelessWidget {
  const KawangiziApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ApiClient>(
      future: ApiClient.create(),
      builder: (context, apiSnapshot) {
        if (!apiSnapshot.hasData) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }
        final api = apiSnapshot.data!;
        final sessionStore = SessionStore();
        final localStore = LocalStore();
        final authRepository = AuthRepository(api: api, sessionStore: sessionStore);
        final scanRepository = ScanRepository(api: api);
        final forumRepository = ForumRepository(localStore: localStore);

        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthController(authRepository: authRepository)),
            ChangeNotifierProvider(create: (_) => CommunityController(forumRepository: forumRepository, localStore: localStore)),
            Provider<ScanRepository>.value(value: scanRepository),
          ],
          child: MaterialApp.router(
            title: 'KawanGizi',
            theme: AppTheme.light,
            debugShowCheckedModeBanner: false,
            routerConfig: createRouter(context.read<AuthController>()),
          ),
        );
      },
    );
  }
}
