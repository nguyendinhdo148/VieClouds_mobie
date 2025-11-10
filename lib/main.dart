import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/Home/home_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authService = AuthService();
  final isLoggedIn = await authService.isLoggedIn();

  runApp(MyApp(isLoggedIn: isLoggedIn));
}


final GoRouter _router = GoRouter(
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => LoginScreen(
        onLoginSuccess: () => context.go('/home'),
      ),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => RegisterScreen(
        onRegisterSuccess: () => context.go('/home'),
      ),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
  ],
  redirect: (context, state) async {
    final authService = AuthService();
    final isLoggedIn = await authService.isLoggedIn();
    final goingToLogin = state.uri.toString() == '/login';
    final goingToRegister = state.uri.toString() == '/register';

    if (isLoggedIn && (goingToLogin || goingToRegister)) {
      return '/home';
    }

    if (!isLoggedIn && !goingToLogin && !goingToRegister) {
      return '/login';
    }

    return null;
  },
);

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final GoRouter router = GoRouter(
      initialLocation: isLoggedIn ? '/home' : '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => LoginScreen(
            onLoginSuccess: () => context.go('/home'),
          ),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => RegisterScreen(
            onRegisterSuccess: () => context.go('/home'),
          ),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'VieJobs App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
