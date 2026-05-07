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
        return CalendarScreen(month: _monthFromState(state));
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

DateTime _monthFromState(GoRouterState state) {
  final DateTime now = DateTime.now();
  final int year =
      int.tryParse(state.uri.queryParameters['year'] ?? '') ?? now.year;
  final int month =
      int.tryParse(state.uri.queryParameters['month'] ?? '') ?? now.month;

  return DateTime(year, month);
}
