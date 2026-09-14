import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app_shell.dart';
import 'app/theme.dart';
import 'providers/app_providers.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/business_setup_screen.dart';
import 'services/auth_service.dart';
import 'services/cloud_config.dart';
import 'services/local_store.dart';
import 'services/migration_service.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocalStore.initialize();
  await MigrationService.run();
  await SupabaseService.initialize();

  runApp(const ProviderScope(child: InvoiceEasyApp()));
}

class InvoiceEasyApp extends StatefulWidget {
  const InvoiceEasyApp({super.key});

  @override
  State<InvoiceEasyApp> createState() => _AppState();
}

class _AppState extends State<InvoiceEasyApp> {
  ThemeMode mode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'InvoiceEasy',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode,
      home: CloudConfig.isConfigured
          ? CloudSessionGate(
              onThemeModeChanged: (value) {
                setState(() => mode = value);
              },
            )
          : _LocalSetupGate(
              onThemeModeChanged: (value) {
                setState(() => mode = value);
              },
            ),
    );
  }
}

class CloudSessionGate extends StatefulWidget {
  const CloudSessionGate({super.key, required this.onThemeModeChanged});

  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<CloudSessionGate> createState() => _CloudSessionGateState();
}

class _CloudSessionGateState extends State<CloudSessionGate> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;

        if (session == null) {
          return const AuthScreen();
        }

        return _AuthenticatedHome(
          onThemeModeChanged: widget.onThemeModeChanged,
        );
      },
    );
  }
}

class _AuthenticatedHome extends ConsumerStatefulWidget {
  const _AuthenticatedHome({required this.onThemeModeChanged});

  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  ConsumerState<_AuthenticatedHome> createState() => _AuthenticatedHomeState();
}

class _AuthenticatedHomeState extends ConsumerState<_AuthenticatedHome> {
  bool _ready = false;
  bool _setupCompleted = false;

  @override
  void initState() {
    super.initState();
    _initializeUserScope();
  }

  Future<void> _initializeUserScope() async {
    final user = AuthService().currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _ready = true;
        });
      }
      return;
    }

    try {
      /*
       * IMPORTANT:
       *
       * Do not mark the application as ready immediately after switching
       * the local scope.
       *
       * The authenticated user's cloud/local data must be bootstrapped
       * first. Otherwise businessProvider can run against an empty local
       * scope and incorrectly display BusinessSetupScreen.
       */
      await LocalStore.switchToUserScope(user.id);

      /*
       * Restore/synchronize the authenticated user's data BEFORE allowing
       * businessProvider/customersProvider/productsProvider/invoicesProvider
       * to evaluate.
       *
       * If the device is offline, bootstrap may fail. In that case we still
       * allow locally cached user-scoped data to be used.
       */
      try {
        await ref.read(syncServiceProvider).bootstrap();
      } catch (_) {
        // Offline/local data remains usable.
      }

      if (!mounted) return;

      /*
       * The repositories may have changed during bootstrap.
       * Invalidate them only after bootstrap has finished.
       */
      ref.invalidate(businessProvider);
      ref.invalidate(customersProvider);
      ref.invalidate(productsProvider);
      ref.invalidate(invoicesProvider);

      /*
       * ONLY NOW is it safe to let the business gate evaluate.
       */
      setState(() {
        _ready = true;
      });
    } catch (_) {
      /*
       * Scope initialization itself failed.
       *
       * We still allow the UI to continue rather than leaving the user
       * permanently stuck on the loading screen.
       */
      if (!mounted) return;

      setState(() {
        _ready = true;
      });
    }
  }

  Future<void> _completeBusinessSetup() async {
    /*
     * The setup screen has already saved the business locally.
     *
     * Sync it to Supabase, but navigation must not depend on the cloud
     * operation succeeding.
     */
    try {
      await ref.read(syncServiceProvider).sync();
    } catch (_) {
      // Local setup remains valid if cloud sync temporarily fails.
    }

    if (!mounted) return;

    /*
     * Refresh all user-scoped data after setup.
     */
    ref.invalidate(businessProvider);
    ref.invalidate(customersProvider);
    ref.invalidate(productsProvider);
    ref.invalidate(invoicesProvider);

    setState(() {
      _setupCompleted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    /*
     * Startup gate.
     *
     * Nothing related to business setup is evaluated until:
     *
     * 1. Authenticated user is known
     * 2. LocalStore is switched to that user
     * 3. Cloud/local bootstrap has completed
     * 4. Providers have been invalidated
     */
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    /*
     * Once setup has been completed during this authenticated session,
     * never evaluate the business gate again.
     */
    if (_setupCompleted) {
      return AppShell(onThemeModeChanged: widget.onThemeModeChanged);
    }

    final business = ref.watch(businessProvider);

    return business.when(
      loading: () {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
      error: (error, stack) {
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 42),
                  const SizedBox(height: 12),
                  const Text(
                    'Could not load your business profile.',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text('$error', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      ref.invalidate(businessProvider);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      data: (profile) {
        final configured =
            profile.name.trim().isNotEmpty &&
            profile.name.trim() != 'My Business';

        /*
         * Existing authenticated business:
         * go directly into the application.
         */
        if (configured) {
          return AppShell(onThemeModeChanged: widget.onThemeModeChanged);
        }

        /*
         * No configured business:
         * first-time authenticated account.
         */
        return BusinessSetupScreen(onComplete: _completeBusinessSetup);
      },
    );
  }
}

class _LocalSetupGate extends ConsumerStatefulWidget {
  const _LocalSetupGate({required this.onThemeModeChanged});

  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  ConsumerState<_LocalSetupGate> createState() => _LocalSetupGateState();
}

class _LocalSetupGateState extends ConsumerState<_LocalSetupGate> {
  bool setupComplete = false;

  @override
  Widget build(BuildContext context) {
    if (setupComplete) {
      return AppShell(onThemeModeChanged: widget.onThemeModeChanged);
    }

    final business = ref.watch(businessProvider);

    return business.when(
      loading: () {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
      error: (error, stack) {
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 42),
                  const SizedBox(height: 12),
                  const Text(
                    'Could not load your business profile.',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text('$error', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      ref.invalidate(businessProvider);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      data: (profile) {
        final configured =
            profile.name.trim().isNotEmpty &&
            profile.name.trim() != 'My Business';

        if (configured) {
          setupComplete = true;

          return AppShell(onThemeModeChanged: widget.onThemeModeChanged);
        }

        return BusinessSetupScreen(
          onComplete: () {
            setState(() {
              setupComplete = true;
            });
          },
        );
      },
    );
  }
}
