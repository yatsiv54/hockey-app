import 'package:flutter/material.dart';
import 'package:nhl_app/devtools/dev_flags.dart';
import 'package:nhl_app/features/matches/domain/entities/match_entity.dart';
import 'package:nhl_app/features/predictor/data/prediction_storage.dart';
import 'package:nhl_app/features/predictor/domain/entities/prediction_record.dart';

class DevTesterFab extends StatefulWidget {
  const DevTesterFab({super.key, required this.onRecordAdded});

  final VoidCallback onRecordAdded;

  @override
  State<DevTesterFab> createState() => _DevTesterFabState();
}

class _DevTesterFabState extends State<DevTesterFab> {
  final _formKey = GlobalKey<FormState>();
  final _storage = PredictionStorage();
  final _matchIdCtrl = TextEditingController();
  final _homeCtrl = TextEditingController(text: 'Home');
  final _awayCtrl = TextEditingController(text: 'Away');
  String _winner = 'home';
  int _startOffsetMinutes = 30;

  @override
  void dispose() {
    _matchIdCtrl.dispose();
    _homeCtrl.dispose();
    _awayCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!enableDevTesterTools) return const SizedBox.shrink();
    return FloatingActionButton.extended(
      heroTag: 'dev_tester_fab',
      icon: const Icon(Icons.bug_report),
      label: const Text('Add Test Match'),
      onPressed: () => _openDialog(context),
    );
  }

  Future<void> _openDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Create Test Prediction'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _matchIdCtrl,
                    decoration: const InputDecoration(labelText: 'Match ID'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Enter match id' : null,
                  ),
                  TextFormField(
                    controller: _homeCtrl,
                    decoration: const InputDecoration(labelText: 'Home Team'),
                  ),
                  TextFormField(
                    controller: _awayCtrl,
                    decoration: const InputDecoration(labelText: 'Away Team'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Winner Prediction',
                    ),
                    value: _winner,
                    onChanged: (v) => setState(() => _winner = v ?? 'home'),
                    items: const [
                      DropdownMenuItem(value: 'home', child: Text('Home')),
                      DropdownMenuItem(value: 'draw', child: Text('Draw')),
                      DropdownMenuItem(value: 'away', child: Text('Away')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Slider(
                    label: 'Start in $_startOffsetMinutes m',
                    min: -120,
                    max: 720,
                    divisions: 84,
                    value: _startOffsetMinutes.toDouble(),
                    onChanged: (v) =>
                        setState(() => _startOffsetMinutes = v.round()),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                await _createRecord();
                if (mounted) {
                  Navigator.of(ctx).pop();
                  widget.onRecordAdded();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Test prediction added')),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createRecord() async {
    final start = DateTime.now().add(Duration(minutes: _startOffsetMinutes));
    final record = PredictionRecord(
      matchId: _matchIdCtrl.text.trim().isEmpty
          ? 'custom_${DateTime.now().millisecondsSinceEpoch}'
          : _matchIdCtrl.text.trim(),
      homeTeam: _homeCtrl.text.trim().isEmpty ? 'Home' : _homeCtrl.text.trim(),
      awayTeam: _awayCtrl.text.trim().isEmpty ? 'Away' : _awayCtrl.text.trim(),
      homeAbbrev: _abbr(_homeCtrl.text.trim().isEmpty ? 'HOM' : _homeCtrl.text.trim()),
      awayAbbrev: _abbr(_awayCtrl.text.trim().isEmpty ? 'AWY' : _awayCtrl.text.trim()),
      winner: _winner,
      overtime: false,
      totalGoals: 5,
      exactScore: '3-2',
      timestamp: DateTime.now(),
      status: MatchStatus.upcoming,
      matchStart: start,
    );
    await _storage.append(record);
  }

  String _abbr(String name) {
    final cleaned = name
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z]'), '');
    if (cleaned.length >= 3) return cleaned.substring(0, 3);
    return (cleaned + 'XXX').substring(0, 3);
  }
}
