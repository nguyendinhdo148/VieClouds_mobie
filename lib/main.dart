// main.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:viejob_app/admin_screen/blogs_screen.dart' show AdminBlogsScreen;
import 'package:viejob_app/admin_screen/companies_screen.dart' show AdminCompaniesScreen;
import 'package:viejob_app/admin_screen/dashboard_screen.dart' show AdminDashboardScreen;
import 'package:viejob_app/admin_screen/jobs_screen.dart' show AdminJobsScreen;
import 'package:viejob_app/admin_screen/users_screen.dart' show AdminUsersScreen;

// Auth screens
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';

// Student screens
import 'screens/nav/home_screen.dart';

// Recruiter screens
import 'recruiter_screen/dashboard_screen.dart';
import 'recruiter_screen/company_screen.dart'; 
import 'recruiter_screen/jobs_screen.dart'; 
import 'recruiter_screen/candidates_screen.dart'; 

// Admin screens


import 'services/auth_service.dart';
import 'widgets/chat/global_ai_chat.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authService = AuthService();
  final isLoggedIn = await authService.isLoggedIn();

  String initialRoute = '/login';

  if (isLoggedIn) {
    final user = await authService.getCurrentUser();
    if (user != null) {
      if (user.role == 'admin') {
        initialRoute = '/admin';
      } else if (user.role == 'recruiter') {
        initialRoute = '/recruiter';
      } else {
        initialRoute = '/home';
      }
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
              if (role == 'admin') {
                context.go('/admin');
              } else if (role == 'recruiter') {
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

        // ADMIN ROUTES
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminDashboardScreen(),
        ),
        GoRoute(
          path: '/admin/users',
          builder: (context, state) => const AdminUsersScreen(),
        ),
        GoRoute(
          path: '/admin/companies',
          builder: (context, state) => const AdminCompaniesScreen(),
        ),
        GoRoute(
          path: '/admin/jobs',
          builder: (context, state) => AdminJobsScreen(
            status: state.uri.queryParameters['status'],
          ),
        ),
        GoRoute(
          path: '/admin/blogs',
          builder: (context, state) => AdminBlogsScreen(
            status: state.uri.queryParameters['status'],
          ),
        ),
      ],
      
      // Error page
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '404',
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Trang không tìm thấy',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Quay về trang đăng nhập'),
              ),
            ],
          ),
        ),
      ),
      
      // Redirect logic
      redirect: (context, state) {
        // Check authentication
        final isLoginRoute = state.matchedLocation == '/login';
        final isRegisterRoute = state.matchedLocation == '/register';
        
        // Allow access to auth pages without login
        if (isLoginRoute || isRegisterRoute) {
          return null;
        }
        
        // For other routes, check if user is logged in
        // This logic will be handled by each screen individually
        return null;
      },
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