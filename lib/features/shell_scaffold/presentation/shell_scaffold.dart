import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nhl_app/core/theme/colors.dart';

class ShellScaffold extends StatelessWidget {
  const ShellScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  int get _index => navigationShell.currentIndex;

  void _resetBranchStack(int index) {
    final branch = navigationShell.route.branches[index];
    branch.navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }

  void _onTap(BuildContext context, int targetIndex) {
    if (targetIndex == _index) {
      _resetBranchStack(targetIndex);
      navigationShell.goBranch(targetIndex, initialLocation: true);
      return;
    }
    _resetBranchStack(_index);
    navigationShell.goBranch(targetIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: SafeArea(top: false, child: navigationShell),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 25),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: CustomColors.navbarColor,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 10, right: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _IconBtn(
                    asset: 'assets/icons/home.png',
                    label: 'Home',
                    active: _index == 0,
                    onTap: () => _onTap(context, 0),
                  ),
                  _IconBtn(
                    asset: 'assets/icons/standings.png',
                    label: 'Standings',
                    active: _index == 1,
                    onTap: () => _onTap(context, 1),
                  ),
                  _IconBtn(
                    asset: 'assets/icons/teams.png',
                    label: 'Teams',
                    active: _index == 2,
                    onTap: () => _onTap(context, 2),
                  ),
                  _IconBtn(
                    asset: 'assets/icons/favorite.png',
                    label: 'Favorites',
                    active: _index == 3,
                    onTap: () => _onTap(context, 3),
                  ),
                  _IconBtn(
                    asset: 'assets/icons/predictor.png',
                    label: 'Predictor',
                    active: _index == 4,
                    onTap: () => _onTap(context, 4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    this.asset,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String? asset;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color iconColor = active ? Colors.black87 : Colors.white;
    final Color bgColor = active ? Colors.white : Colors.transparent;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        height: 36,
        constraints: const BoxConstraints(minWidth: 36),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (asset != null)
              ImageIcon(AssetImage(asset!), size: 18, color: iconColor),
            if (active) ...[
              const SizedBox(width: 4),
              Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
