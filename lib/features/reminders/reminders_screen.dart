import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/app_state.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Tasks')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Task title',
              hintText: 'Move car / buy groceries / call mechanic',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () async {
              if (_controller.text.trim().isEmpty) return;
              await appState.addReminder(
                _controller.text.trim(),
                DateTime.now().add(const Duration(hours: 1)),
              );
              _controller.clear();
            },
            child: const Text('Add 1-hour reminder'),
          ),
          const SizedBox(height: 16),
          ...appState.reminders.map(
            (item) => Card(
              child: ListTile(
                title: Text(item.title),
                subtitle: Text(item.when.toString()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
