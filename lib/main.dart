// main.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/nav/home_screen.dart';
import 'recruiter_screen/dashboard_screen.dart';
import 'recruiter_screen/company_screen.dart'; 
import 'recruiter_screen/jobs_screen.dart'; 
import 'recruiter_screen/candidates_screen.dart'; 
import 'services/auth_service.dart';
import 'widgets/chat/global_ai_chat.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authService = AuthService();
  final isLoggedIn = await authService.isLoggedIn();

  String initialRoute = '/login';

  if (isLoggedIn) {
    final user = await authService.getCurrentUser();
    if (user != null && user.role == 'recruiter') {
      initialRoute = '/recruiter';
    } else {
      initialRoute = '/home';
    }
  }

  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({Key? key, required this.initialRoute}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: initialRoute,
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => LoginScreen(
            onLoginSuccess: (role) {
              if (role == 'recruiter') {
                context.go('/recruiter');
              } else {
                context.go('/home');
              }
            },
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

        // RECRUITER ROUTES
        GoRoute(
          path: '/recruiter',
          builder: (context, state) => const DashboardScreen(),
          routes: [
            GoRoute(
              path: 'company',
              builder: (context, state) => const CompanyScreen(),
            ),
            GoRoute(
              path: 'jobs',
              builder: (context, state) => const JobsScreen(),
            ),
            GoRoute(
              path: 'candidates',
              builder: (context, state) => const CandidatesScreen(),
            ),
          ],
        ),
      ],
    );

    return MaterialApp.router(
      title: 'VieJobs App',
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      builder: (context, child) {
        return GlobalAIChat(
          child: child ?? const SizedBox(),
        );
      },
    );
  }
}