import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/app_state.dart';

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Daily News')),
      body: RefreshIndicator(
        onRefresh: appState.refreshNews,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: appState.speakNewsBriefing,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Play Cantonese News'),
                ),
                FilledButton.tonal(
                  onPressed: appState.refreshNews,
                  child: const Text('Refresh Headlines'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...appState.newsItems.map(
              (item) => Card(
                child: ListTile(
                  title: Text(item.title),
                  subtitle: Text(
                    '${item.source} • ${item.category}\n${item.summary}',
                  ),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () async {
                    final uri = Uri.parse(item.link);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ),
            ),
            if (appState.newsItems.isEmpty)
              const Card(
                child: ListTile(
                  title: Text('No headlines loaded yet'),
                  subtitle: Text('Tap Refresh Headlines or Play Cantonese News.'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
