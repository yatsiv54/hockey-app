import 'package:flutter/material.dart';
import 'package:nhl_app/core/theme/colors.dart';
import 'package:nhl_app/features/settings/presentation/pages/settings_page.dart';

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.actions = const [],
    this.showSettings = true,
    this.bottomGap = 12,
    this.onSettingsTap,
    this.oneLine = false,
  });

  final String title;
  final List<Widget> actions;
  final bool showSettings;
  final double bottomGap;
  final VoidCallback? onSettingsTap;
  final bool oneLine;

  @override
  Widget build(BuildContext context) {
    final defaultSettingsTap = onSettingsTap ??
        () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SettingsPage()),
          );
        };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          color: CustomColors.appbarColor,
          padding:
              const EdgeInsets.only(left: 25, top: 8, right: 15, bottom: 8),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    maxLines: oneLine ? 1 : 2,
                    overflow: TextOverflow.clip,
                    title,
                    style: const TextStyle(
                      height: 1,
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                ...actions,
                if (showSettings)
                  IconButton(
                    onPressed: defaultSettingsTap,
                    icon: Image.asset(
                      'assets/icons/settings.png',
                      width: 24,
                      height: 24,
                    ),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(height: bottomGap),
      ],
    );
  }
}
