import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/sign_in_screen.dart';
import 'screens/task_dashboard.dart';
import 'services/in_memory_task_service.dart';
import 'services/notification_service.dart';
import 'services/task_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const demoMode = bool.fromEnvironment('DEMO_MODE');
  if (demoMode) {
    runApp(const TaskApp(demoMode: true));
    return;
  }

  try {
    await Firebase.initializeApp();
    await NotificationService.initialize();
    runApp(const TaskApp());
  } catch (error) {
    runApp(TaskApp(startupError: error.toString()));
  }
}

class TaskApp extends StatefulWidget {
  const TaskApp({this.demoMode = false, this.startupError, super.key});

  final bool demoMode;
  final String? startupError;

  @override
  State<TaskApp> createState() => _TaskAppState();
}

class _TaskAppState extends State<TaskApp> {
  ThemeMode _themeMode = ThemeMode.system;
  bool _isDemoSignedIn = false;
  final TaskRepository _demoTaskService = InMemoryTaskService();

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final preferences = await SharedPreferences.getInstance();
    final isDark = preferences.getBool('darkTheme') ?? false;
    if (mounted) {
      setState(() => _themeMode = isDark ? ThemeMode.dark : ThemeMode.light);
    }
  }

  Future<void> _toggleTheme() async {
    final isDark = _themeMode != ThemeMode.dark;
    setState(() => _themeMode = isDark ? ThemeMode.dark : ThemeMode.light);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('darkTheme', isDark);
  }

  void _signInToDemo() => setState(() => _isDemoSignedIn = true);

  void _signOutOfDemo() => setState(() => _isDemoSignedIn = false);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestor de tareas',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB63D68),
          secondary: const Color(0xFF287C72),
          tertiary: const Color(0xFFD59A42),
          surface: const Color(0xFFFFFBFC),
        ),
        scaffoldBackgroundColor: const Color(0xFFFFF7F9),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFFBFC),
          foregroundColor: Color(0xFF29242A),
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFFFFFEFF),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: const Color(0xFFB63D68).withAlpha(30)),
          ),
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF08EAD),
          secondary: const Color(0xFF83C9BE),
          tertiary: const Color(0xFFE7BD73),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (widget.startupError != null) {
      return FirebaseSetupScreen(error: widget.startupError!);
    }
    if (widget.demoMode) {
      if (!_isDemoSignedIn) {
        return SignInScreen(
          demoMode: true,
          onDemoSignIn: _signInToDemo,
        );
      }

      return TaskDashboard(
        userId: 'demo-user',
        themeMode: _themeMode,
        onToggleTheme: _toggleTheme,
        taskRepository: _demoTaskService,
        onSignOut: _signOutOfDemo,
        demoMode: true,
      );
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        if (user == null) return const SignInScreen();

        return TaskDashboard(
          userId: user.uid,
          themeMode: _themeMode,
          onToggleTheme: _toggleTheme,
          taskRepository: TaskService(),
          onSignOut: FirebaseAuth.instance.signOut,
        );
      },
    );
  }
}

class FirebaseSetupScreen extends StatelessWidget {
  const FirebaseSetupScreen({required this.error, super.key});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Firebase aun no esta configurado',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Para probar la interfaz sin Firebase, inicia Flutter con '
                  '--dart-define=DEMO_MODE=true.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SelectableText(error, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
