import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nhl_app/core/di/di.dart';
import 'package:nhl_app/core/router/routes.dart';
import 'package:nhl_app/features/welcome/data/welcome_storage.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  static const int blocks = 16;
  static const Duration tick = Duration(milliseconds: 130);
  int filled = 0;
  Timer? _timer;
  bool _navigated = false;
  final _welcomeStorage = getIt<WelcomeStorage>();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(tick, (t) {
      if (!mounted) return;
      setState(() {
        if (filled < blocks) {
          filled += 1;
        }
        if (filled >= blocks && !_navigated) {
          _navigated = true;
          t.cancel();
          _navigateNext();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _navigateNext() async {
    final completed = await _welcomeStorage.isCompleted();
    if (!mounted) return;
    if (completed) {
      context.go(Routes.upcoming);
    } else {
      context.go(Routes.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color active = Color.fromRGBO(136, 170, 47, 1);
    final Color inactive = Colors.grey.shade700;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Loading...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(blocks, (i) {
                final bool isActive = i < filled;
                return AnimatedContainer(
                  curve: Curves.easeOut,
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 2.2),
                  width: 14,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isActive ? active : inactive,
                    borderRadius: BorderRadius.circular(1),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
