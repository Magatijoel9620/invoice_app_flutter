import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app_shell.dart';
import 'app/theme.dart';
import 'providers/app_providers.dart';
import 'core/providers/subscription_providers.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/business_setup_screen.dart';
import 'services/auth_service.dart';
import 'core/errors/app_error.dart';
import 'services/cloud_config.dart';
import 'services/local_store.dart';
import 'services/migration_service.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocalStore.initialize();
  await MigrationService.run();
  await SupabaseService.initialize();

  runApp(
    const ProviderScope(child: _ConnectivityStartup(child: InvoiceEasyApp())),
  );
}

class _ConnectivityStartup extends ConsumerStatefulWidget {
  const _ConnectivityStartup({required this.child});

  final Widget child;

  @override
  ConsumerState<_ConnectivityStartup> createState() =>
      _ConnectivityStartupState();
}

class _ConnectivityStartupState extends ConsumerState<_ConnectivityStartup> {
  @override
  void initState() {
    super.initState();
    // Provider creation starts ConnectivityService immediately. Keeping this
    // bootstrap outside the authenticated shell means connectivity is ready
    // before the first dashboard/sync transition.
    ref.read(connectivityProvider);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class InvoiceEasyApp extends StatefulWidget {
  const InvoiceEasyApp({super.key});

  @override
  State<InvoiceEasyApp> createState() => _AppState();
}

class _AppState extends State<InvoiceEasyApp> {
  final ThemeProvider _themeProvider = ThemeProvider();
  bool _themeReady = false;

  @override
  void initState() {
    super.initState();
    _initializeTheme();
  }

  Future<void> _initializeTheme() async {
    await _themeProvider.initialize();

    if (!mounted) return;

    _themeProvider.addListener(_onThemeChanged);

    setState(() {
      _themeReady = true;
    });
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  void _changeTheme(ThemeMode mode) {
    _themeProvider.setThemeMode(mode);
  }

  @override
  void dispose() {
    _themeProvider.removeListener(_onThemeChanged);
    _themeProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_themeReady) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'InvoiceEasy',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeProvider.mode,
      home: CloudConfig.isConfigured
          ? CloudSessionGate(onThemeModeChanged: _changeTheme)
          : _LocalSetupGate(onThemeModeChanged: _changeTheme),
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
  StreamSubscription<AuthState>? _authSubscription;
  bool _passwordRecoveryPending = false;

  @override
  void initState() {
    super.initState();
    _authSubscription = AuthService().authStateChanges.listen((state) {
      if (state.event == AuthChangeEvent.passwordRecovery && mounted) {
        setState(() => _passwordRecoveryPending = true);
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_passwordRecoveryPending) {
      return PasswordRecoveryScreen(
        onCompleted: () {
          if (mounted) setState(() => _passwordRecoveryPending = false);
        },
      );
    }
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
      // Restore the business to the cloud BEFORE calling the billing bridge.
      // InvoiceEasy's billing bridge resolves its billing resource through the
      // authenticated user's cloud businesses row. Calling subscription
      // bootstrap first on a new account therefore returns "business not found".
      try {
        await ref.read(syncServiceProvider).bootstrap();
      } catch (error, stack) {
        debugPrint(
          'InvoiceEasy startup: sync bootstrap failed '
          '(${error.runtimeType}); local data will remain available.',
        );
        debugPrintStack(stackTrace: stack);
      }

      // Only initialize billing after a configured business is available.
      // This avoids a failed first-login snapshot being silently treated as
      // an initialized trial. ensureSubscription is expected to be idempotent
      // and must preserve any existing trial dates.
      final localBusiness = await ref.read(businessRepositoryProvider).get();
      final hasConfiguredBusiness =
          localBusiness != null &&
          localBusiness.name.trim().isNotEmpty &&
          localBusiness.name.trim() != 'My Business';
      if (hasConfiguredBusiness) {
        try {
          await ref.read(subscriptionBootstrapProvider.future);
        } catch (error, stack) {
          debugPrint(
            'InvoiceEasy startup: subscription bootstrap failed '
            '(${error.runtimeType}); access will be rechecked when online.',
          );
          debugPrintStack(stackTrace: stack);
        }
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
    } catch (error, stack) {
      // Keep the app usable with account-scoped local data, but retain a
      // debug-only diagnostic instead of silently hiding startup failures.
      debugPrint(
        'InvoiceEasy startup: user-scope initialization failed '
        '(${error.runtimeType}).',
      );
      debugPrintStack(stackTrace: stack);
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
    var cloudBusinessSynced = false;
    try {
      await ref.read(syncServiceProvider).sync();
      cloudBusinessSynced = ref.read(connectivityProvider).isOnline;
    } catch (error, stack) {
      debugPrint(
        'InvoiceEasy setup: cloud sync did not complete '
        '(${error.runtimeType}); keeping the locally saved business.',
      );
      debugPrintStack(stackTrace: stack);
    }

    // Trial/subscription bootstrap must run only after the cloud business row
    // exists. Never reset or recreate a trial here; the billing service owns
    // idempotency and existing subscription dates.
    if (cloudBusinessSynced) {
      try {
        await ref.read(subscriptionBootstrapProvider.future);
      } catch (error, stack) {
        debugPrint(
          'InvoiceEasy setup: subscription bootstrap deferred '
          '(${error.runtimeType}).',
        );
        debugPrintStack(stackTrace: stack);
      }
    }

    if (!mounted) return;

    ref.invalidate(businessProvider);
    ref.invalidate(customersProvider);
    ref.invalidate(productsProvider);
    ref.invalidate(invoicesProvider);
    ref.invalidate(subscriptionBootstrapProvider);
    ref.invalidate(subscriptionPlansProvider);
    ref.invalidate(currentSubscriptionProvider);
    ref.invalidate(subscriptionStatusProvider);
    ref.invalidate(paymentTransactionsProvider);

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
                  Text(
                    AppErrorHandler.message(error, operation: 'business.load'),
                    textAlign: TextAlign.center,
                  ),
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
                  Text(
                    AppErrorHandler.message(error, operation: 'business.load'),
                    textAlign: TextAlign.center,
                  ),
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
