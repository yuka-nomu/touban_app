import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/models.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  _registerHiveAdapters();

  runApp(const ProviderScope(child: MyApp()));
}

void _registerHiveAdapters() {
  if (!Hive.isAdapterRegistered(MemberAdapter().typeId)) {
    Hive.registerAdapter(MemberAdapter());
  }
  if (!Hive.isAdapterRegistered(CalendarDayAdapter().typeId)) {
    Hive.registerAdapter(CalendarDayAdapter());
  }
  if (!Hive.isAdapterRegistered(MonthScheduleAdapter().typeId)) {
    Hive.registerAdapter(MonthScheduleAdapter());
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: '登校班当番表',
      theme: AppTheme.light(),
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
