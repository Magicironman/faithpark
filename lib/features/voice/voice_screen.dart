import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/app_state.dart';

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  bool _isListening = false;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = Theme.of(context);
    final isCantonese = appState.isCantoneseMode;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFEEE3C5),
            Color(0xFFF7F3EA),
            Color(0xFFE4EFE8),
          ],
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
          children: [
            Text(
              isCantonese ? '廣東話助理' : 'Voice Agent',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF14342B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isCantonese
                  ? '主力支援泊車、今日天氣、附近交通同經文語音。按一下收音，直接講你需要。'
                  : 'Focused on parking, weather, nearby traffic, and scripture voice support.',
              style: theme.textTheme.titleMedium?.copyWith(
                color: const Color(0xFF50675D),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF14342B),
                    Color(0xFF245E4C),
                  ],
                ),
              ),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening
                          ? const Color(0xFFD7A84A)
                          : Colors.white.withValues(alpha: 0.12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                        width: 2,
                      ),
                    ),
                    child: IconButton(
                      iconSize: 44,
                      color: Colors.white,
                      onPressed: () => _startListening(appState),
                      icon: Icon(
                        _isListening ? Icons.graphic_eq_rounded : Icons.mic_rounded,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _isListening
                        ? (isCantonese ? '收音中...' : 'Listening...')
                        : (isCantonese ? '點一下開始講話' : 'Tap to start speaking'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isCantonese
                        ? '例如：我架車喺邊、仲有幾多時間、今日天氣、附近交通 5 英里、讀今日金句'
                        : 'Example: where is my car, how much time is left, weather today, nearby traffic 10 miles, read today’s verse',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.78),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _PanelCard(
              title: isCantonese ? '你講咗' : 'You said',
              body: appState.lastAgentHeard.isEmpty
                  ? (isCantonese ? '未有語音輸入。' : 'No voice input yet.')
                  : appState.lastAgentHeard,
            ),
            const SizedBox(height: 14),
            _PanelCard(
              title: isCantonese ? '助理回應' : 'Agent reply',
              body: appState.lastAgentReply,
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _PromptChip(
                  label: isCantonese ? '我架車喺邊' : 'Where is my car',
                  onTap: () => _runPrompt(appState, isCantonese ? '我架車喺邊' : 'where is my car'),
                ),
                _PromptChip(
                  label: isCantonese ? '仲有幾多時間' : 'Time left',
                  onTap: () => _runPrompt(appState, isCantonese ? '仲有幾多時間' : 'how much time left'),
                ),
                _PromptChip(
                  label: isCantonese ? '今日天氣' : 'Weather today',
                  onTap: () => _runPrompt(appState, isCantonese ? '今日天氣' : 'weather today'),
                ),
                _PromptChip(
                  label: isCantonese ? '附近交通 5 英里' : 'Traffic 5 miles',
                  onTap: () => _runPrompt(appState, isCantonese ? '附近交通 5 英里' : 'nearby traffic 5 miles'),
                ),
                _PromptChip(
                  label: isCantonese ? '附近交通 20 英里' : 'Traffic 20 miles',
                  onTap: () => _runPrompt(appState, isCantonese ? '附近交通 20 英里' : 'nearby traffic 20 miles'),
                ),
                _PromptChip(
                  label: isCantonese ? '讀今日金句' : 'Read daily verse',
                  onTap: () => _runPrompt(appState, isCantonese ? '讀今日金句' : 'read today’s verse'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startListening(AppState appState) async {
    final ready = await appState.speechService.init();
    if (!ready) {
      if (!mounted) {
        return;
      }
      setState(() => _isListening = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appState.isCantoneseMode
                ? '語音辨識暫時未能使用。'
                : 'Speech recognition is not available.',
          ),
        ),
      );
      return;
    }

    setState(() => _isListening = true);
    await appState.speechService.listen(
      localeId: appState.isCantoneseMode ? 'yue-Hant-HK' : 'en-CA',
      onResult: (text) async {
        await appState.handleVoiceCommand(text);
        if (mounted) {
          setState(() => _isListening = false);
        }
      },
    );
  }

  Future<void> _runPrompt(AppState appState, String text) async {
    await appState.handleVoiceCommand(text);
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(
                color: const Color(0xFF8C6730),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              body,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: const Color(0xFF1A362D),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromptChip extends StatelessWidget {
  const _PromptChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: const Icon(Icons.bolt_rounded, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}
