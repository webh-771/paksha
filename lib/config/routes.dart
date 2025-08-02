import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paksha/views/auth/login_page.dart';
import 'package:paksha/views/auth/register_page.dart';
import 'package:paksha/views/home/home_page.dart';
import 'package:paksha/recipes/recipes_page.dart';
import 'package:paksha/shopping_list/shopping_list_page.dart';
import 'package:paksha/profile/profile_page.dart';
import 'package:paksha/pantry/pantry_page.dart';
import '../views/navigation/main_nav.dart';
import '../providers/recipes_provider.dart';

// Example of a Riverpod ChangeNotifierProvider for recipes
final recipesProvider = ChangeNotifierProvider<RecipesProvider>((ref) => RecipesProvider());

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/pantry',
        builder: (context, state) => const PantryPage(),
      ),

      // SHELL ROUTE: NavBar always visible on main pages
      ShellRoute(
        builder: (context, state, child) => MainNav(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: '/recipes',
            builder: (context, state) => ProviderScope(
              overrides: [
                recipesProvider.overrideWith((ref) => RecipesProvider()),
              ],
              child: RecipesPage(),
            ),
          ),
          /*GoRoute(
            path: '/shopping-list',
            builder: (context, state) => const ShoppingListPage(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfilePage(),


          ),

           */
        ],
      ),
    ],
  );
}
