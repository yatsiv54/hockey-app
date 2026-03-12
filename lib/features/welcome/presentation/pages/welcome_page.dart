import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:nhl_app/core/di/di.dart';
import 'package:nhl_app/core/router/routes.dart';
import 'package:nhl_app/core/theme/colors.dart';
import 'package:nhl_app/features/settings/application/app_settings_controller.dart';
import 'package:nhl_app/features/settings/domain/entities/app_settings.dart';
import 'package:nhl_app/features/welcome/data/welcome_storage.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final _settings = getIt<AppSettingsController>();
  final _welcomeStorage = getIt<WelcomeStorage>();
  final DateFormat _format = DateFormat('dd.MM.yyyy');

  late DateTime _selectedDate;
  late bool _goalAlerts;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _goalAlerts = _settings.value.goalAlerts;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now.subtract(const Duration(days: 2)),
      lastDate: now.add(const Duration(days: 7)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _start() async {
    if (_processing) return;
    setState(() => _processing = true);
    final option = _resolveDefaultDate(_selectedDate);
    await _settings.updateGoalAlerts(_goalAlerts);
    await _settings.updatePreferredDate(_selectedDate);
    await _settings.updateDefaultDate(option);
    await _welcomeStorage.markCompleted();
    if (!mounted) return;
    context.go(Routes.upcoming);
  }

  DefaultDateOption _resolveDefaultDate(DateTime date) {
    final now = DateTime.now();
    final diff = DateTime(
      date.year,
      date.month,
      date.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff <= -1) return DefaultDateOption.yesterday;
    if (diff >= 1) return DefaultDateOption.tomorrow;
    return DefaultDateOption.today;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            left: -150,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Stack(
                children: [
                  Opacity(
                    opacity: 0.25,
                    child: Image.asset(
                      'assets/icons/welcome.jpg',
                      width: double.infinity,
                      height: 540,
                      fit: BoxFit.cover,
                      alignment: Alignment.bottomCenter,
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [0.01, 0.7],
                            colors: [
                              CustomColors.backgroundColor,
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 50),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        textAlign: TextAlign.center,
                        'Welcome to\nPuckVision',
                        style: TextStyle(
                          height: 1.2,
                          color: Colors.white,
                          fontSize: 55,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      textAlign: TextAlign.center,
                      'Follow live NHL games, check stats, and play the Puck Predictor mini-game.',
                      style: TextStyle(color: Colors.white, fontSize: 19),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Date:',
                      style: TextStyle(
                        color: Color.fromRGBO(77, 127, 169, 1),
                        fontWeight: FontWeight.w500,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(35, 86, 130, 1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _format.format(_selectedDate),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              splashRadius: 18,
                              onPressed: () => setState(
                                () => _selectedDate = DateTime.now(),
                              ),
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(35, 86, 130, 1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Goal Notifications',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Switch(
                            value: _goalAlerts,
                            onChanged: (value) =>
                                setState(() => _goalAlerts = value),
                            thumbColor: WidgetStateProperty.resolveWith<Color?>(
                              (states) => states.contains(WidgetState.selected)
                                  ? const Color(0xFFA8C93E)
                                  : Colors.white54,
                            ),
                            trackColor: WidgetStateProperty.all(Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 70,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromRGBO(136, 170, 47, 1),
                          foregroundColor: Colors.black,
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _processing ? null : _start,
                        child: Text(
                          _processing ? 'Loading...' : "Let's Start",
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
