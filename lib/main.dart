import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/todo_provider.dart';
import 'providers/calendar_provider.dart';
import 'services/notification_service.dart';
import 'utils/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Notifications
  await NotificationService().initialize();

  // Korean locale
  await initializeDateFormatting('ko', null);

  runApp(const CamdoApp());
}

class CamdoApp extends StatelessWidget {
  const CamdoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => TodoProvider()),
        ChangeNotifierProvider(create: (_) => CalendarProvider()..initSilently()),
      ],
      child: MaterialApp(
        title: 'Camdo',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const _AppEntry(),
      ),
    );
  }
}

class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isSignedIn) {
      context.read<TodoProvider>().startListening();
    }
    authProvider.authStateChanges.listen((user) {
      if (user != null && mounted) {
        context.read<TodoProvider>().startListening();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (ctx, auth, _) {
        if (auth.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
          );
        }
        if (auth.isSignedIn) {
          return const MainShell();
        }
        return const LoginScreen();
      },
    );
  }
}
