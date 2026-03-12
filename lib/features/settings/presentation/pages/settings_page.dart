import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nhl_app/core/di/di.dart';
import 'package:nhl_app/core/router/routes.dart';
import 'package:nhl_app/core/theme/colors.dart';
import 'package:nhl_app/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:nhl_app/features/settings/application/app_settings_controller.dart';
import 'package:nhl_app/features/settings/domain/entities/app_settings.dart';
import 'package:nhl_app/features/predictor/data/prediction_storage.dart';
import 'package:nhl_app/features/matches/application/goal_alert_registry.dart';
import 'package:nhl_app/features/welcome/data/welcome_storage.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final AppSettingsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = getIt<AppSettingsController>();
    _controller.addListener(_onSettingsChanged);
    _controller.ensureLoaded();
  }

  @override
  void dispose() {
    _controller.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _SettingsHeader(onClose: () => Navigator.of(context).maybePop()),
            Expanded(
              child: _controller.isInitialized
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Material(
                        color: Colors.transparent,
                        child: _SettingsContent(
                          settings: _controller.value,
                          controller: _controller,
                        ),
                      ),
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1F4E7B),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, color: Colors.white),
          ),
          const Text(
            'Settings',
            style: TextStyle(
              letterSpacing: 1,
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsContent extends StatelessWidget {
  const _SettingsContent({required this.settings, required this.controller});

  final AppSettings settings;
  final AppSettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SettingSwitchRow(
          label: 'Goal Alerts:',
          value: settings.goalAlerts,
          onChanged: controller.updateGoalAlerts,
        ),
        _SettingSwitchRow(
          label: 'Final Score Alerts:',
          value: settings.finalScoreAlerts,
          onChanged: controller.updateFinalScoreAlerts,
        ),
        _SettingSwitchRow(
          label: 'Enable Predictor Notifications:',
          value: settings.predictorNotifications,
          onChanged: controller.updatePredictorNotifications,
        ),
        const SizedBox(height: 16),
        const Text(
          'Default Date:',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 8),
        _DateSelector(
          active: settings.defaultDate,
          onChanged: (option) {
            controller.updateDefaultDate(option);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Default date updated')),
            );
          },
        ),
        const SizedBox(height: 24),
        const Text(
          'About:',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Powered by NHL Stats API -- Open Data Initiative.',
          style: TextStyle(color: Colors.white, fontSize: 15),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _DangerSection extends StatelessWidget {
  const _DangerSection({required this.controller});
  final AppSettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Danger Zone',
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          icon: const Icon(Icons.delete_forever),
          label: const Text(
            'Delete all local data',
            style: TextStyle(color: Colors.white),
          ),
          onPressed: () => _confirm(context),
        ),
      ],
    );
  }

  void _confirm(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete all data?'),
        content: const Text(
          'This will remove favorites, predictions and settings stored locally.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _clearData(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearData(BuildContext context) async {
    await context.read<FavoritesCubit>().clearAll();
    await getIt<PredictionStorage>().clear();
    await getIt<GoalAlertRegistry>().clear();
    await controller.resetToDefaults();
    await getIt<WelcomeStorage>().reset();
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Local data cleared')));
    await Future.delayed(const Duration(milliseconds: 300));
    if (!context.mounted) return;
    context.go(Routes.welcome);
  }
}

class _SettingSwitchRow extends StatelessWidget {
  const _SettingSwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(35, 86, 130, 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeTrackColor: Color.fromRGBO(136, 170, 47, 1),
              activeThumbColor: Color.fromRGBO(136, 170, 47, 1),
              inactiveThumbColor: Color.fromRGBO(193, 193, 193, 1),
              trackColor: WidgetStateProperty.all(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({required this.active, required this.onChanged});

  final DefaultDateOption active;
  final ValueChanged<DefaultDateOption> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = [
      DefaultDateOption.today,
      DefaultDateOption.yesterday,
      DefaultDateOption.tomorrow,
    ];
    const labels = {
      DefaultDateOption.today: 'Today',
      DefaultDateOption.yesterday: 'Yesterday',
      DefaultDateOption.tomorrow: 'Tomorrow',
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final option in options)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () => onChanged(option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: option == active
                        ? const Color.fromRGBO(136, 170, 47, 1)
                        : const Color.fromRGBO(35, 86, 130, 1),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    labels[option]!,
                    style: TextStyle(
                      fontSize: 19,
                      color: option == active
                          ? Colors.white
                          : Color.fromRGBO(83, 138, 185, 1),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
