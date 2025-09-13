import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'auth/auth_gate.dart';
import 'features/lists/lists_screen.dart';
import 'features/items/items_screen.dart';

GoRouter createRouter() => GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const AuthGate(child: ListsScreen()),
        ),
        GoRoute(
          path: '/lists/:id',
          builder: (context, state) => AuthGate(
            child: ItemsScreen(listId: state.pathParameters['id']!),
          ),
        ),
      ],
    );
