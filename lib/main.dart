import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/services/app_state.dart';
import 'core/services/notification_service.dart';
import 'core/services/settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_HK');
  await initializeDateFormatting('en');

  final settingsService = SettingsService();
  await settingsService.init();

  final notificationService = NotificationService();
  await notificationService.init();

  final appState = AppState(
    settingsService: settingsService,
    notificationService: notificationService,
  );
  await appState.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appState),
      ],
      child: const TorontoAiParkingApp(),
    ),
  );
}
