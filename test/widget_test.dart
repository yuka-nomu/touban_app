import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:touban_app/main.dart';
import 'package:touban_app/models/models.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    const MethodChannel pathProviderChannel = MethodChannel(
      'plugins.flutter.io/path_provider',
    );
    final Directory tempDir = await Directory.systemTemp.createTemp();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'getApplicationDocumentsDirectory':
              return tempDir.path;
            case 'getTemporaryDirectory':
              return tempDir.path;
            default:
              return null;
          }
        });

    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(MemberAdapter().typeId)) {
      Hive.registerAdapter(MemberAdapter());
    }
    if (!Hive.isAdapterRegistered(MemberSettingAdapter().typeId)) {
      Hive.registerAdapter(MemberSettingAdapter());
    }
    if (!Hive.isAdapterRegistered(CalendarDayAdapter().typeId)) {
      Hive.registerAdapter(CalendarDayAdapter());
    }
    if (!Hive.isAdapterRegistered(MonthScheduleAdapter().typeId)) {
      Hive.registerAdapter(MonthScheduleAdapter());
    }
    await Hive.deleteBoxFromDisk('member_settings');
    await Hive.deleteBoxFromDisk('member_setting_selection');
    await Hive.deleteBoxFromDisk('members');
  });

  testWidgets('app opens the home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pump();

    expect(find.text('登校班当番表'), findsOneWidget);
  });
}
