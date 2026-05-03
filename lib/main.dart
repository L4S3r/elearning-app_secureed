  import 'package:flutter/material.dart';
  import 'theme.dart';
  import 'screens/landing_screen.dart';
  import 'screens/signin_screen.dart';
  import 'screens/signup_screen.dart';
  import 'screens/forgot_password_screen.dart';
  import 'screens/welcome_screen.dart';
  import 'screens/home_screen.dart';

  void main() {
    WidgetsFlutterBinding.ensureInitialized();
    runApp(const ELearningApp());
  }

  class ELearningApp extends StatelessWidget {
    const ELearningApp({super.key});

    @override
    Widget build(BuildContext context) {
      return MaterialApp(
        title: 'E-Learning',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        initialRoute: '/welcome',
        routes: {
          '/': (context) => const LandingScreen(),
          // ignore: prefer_const_constructors
          '/signin': (context) => SignInScreen(),
          '/signup': (context) => const SignUpScreen(),
          // ignore: prefer_const_constructors
          '/forgot': (context) => ForgotPasswordScreen(),
          '/welcome': (context) => const WelcomeScreen(),
          '/home': (context) => const HomeScreen(),
        },
      );
    }
  }
