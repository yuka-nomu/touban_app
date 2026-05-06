import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/calendar_screen.dart';
import '../screens/home_screen.dart';
import '../screens/settings_screen.dart';

final GoRouter appRouter = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen();
      },
    ),
    GoRoute(
      path: '/calendar',
      builder: (BuildContext context, GoRouterState state) {
        return CalendarScreen();
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (BuildContext context, GoRouterState state) {
        return const SettingsScreen();
      },
    ),
  ],
);
