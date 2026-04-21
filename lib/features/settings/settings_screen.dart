import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/app_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isCantonese = appState.settingsService.speakInCantonese;
    final defaultParking =
        appState.settingsService.defaultParkingMinutes.toDouble();
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF4E6C8),
            Color(0xFFF8F3E8),
            Color(0xFFE3EEE7),
          ],
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
          children: [
            Text(
              isCantonese ? '設定' : 'Settings',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF14342B),
              ),
            ),
            const SizedBox(height: 18),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    value: isCantonese,
                    title: Text(isCantonese ? '廣東話語音' : 'Cantonese voice'),
                    subtitle: Text(
                      isCantonese
                          ? '關閉後使用英文語音'
                          : 'Turn off to use English voice',
                    ),
                    onChanged: (value) async {
                      await appState.setLanguage(
                        code: value ? 'zh' : 'en',
                        cantoneseVoice: value,
                      );
                    },
                  ),
                  ListTile(
                    title: Text(
                      isCantonese ? '預設泊車分鐘' : 'Default parking duration',
                    ),
                    subtitle: Slider(
                      value: defaultParking,
                      min: 30,
                      max: 360,
                      divisions: 11,
                      label: '${defaultParking.round()} min',
                      onChanged: (value) =>
                          appState.updateDefaultParkingMinutes(
                        value.round(),
                      ),
                    ),
                    trailing: Text(
                      '${defaultParking.round()}m',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
