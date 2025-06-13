import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paksha/views/auth/login_page.dart';
import 'package:paksha/views/auth/register_page.dart';
import 'package:paksha/views/home/home_page.dart';
import 'package:paksha/pantry/pantry_page.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
      GoRoute(path: '/home', builder: (_, __) => const HomePage()),
      GoRoute(path: '/pantry', builder: (_, __) => const PantryPage()),
    ],
  );
}
