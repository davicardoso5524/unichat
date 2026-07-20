import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unichat/config/supabase_config.dart';
import 'package:unichat/routes/app_router.dart';
import 'package:unichat/theme/app_theme.dart';
import 'package:unichat/controllers/auth_controller.dart';
import 'package:unichat/controllers/chat_controller.dart';
import 'package:unichat/controllers/group_controller.dart';
import 'package:unichat/controllers/home_controller.dart';
import 'package:unichat/controllers/profile_controller.dart';
import 'package:unichat/controllers/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => HomeController()),
        ChangeNotifierProvider(create: (_) => ChatController()),
        ChangeNotifierProvider(create: (_) => GroupController()),
        ChangeNotifierProvider(create: (_) => ProfileController()),
        ChangeNotifierProvider(create: (_) => ThemeController()),
      ],
      child: const UniChatApp(),
    ),
  );
}

class UniChatApp extends StatefulWidget {
  const UniChatApp({super.key});

  @override
  State<UniChatApp> createState() => _UniChatAppState();
}

class _UniChatAppState extends State<UniChatApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final authController = context.read<AuthController>();
    _router = createRouter(authController);
  }

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();

    return MaterialApp.router(
      title: 'UniChat',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      themeMode: themeController.modoTema,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
    );
  }
}
