import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:nhl_app/core/di/di.dart';
import 'package:nhl_app/core/theme/colors.dart';
import 'package:nhl_app/core/widgets/page_header.dart';
import 'package:nhl_app/features/player/domain/entities/player_detail.dart';
import 'package:nhl_app/features/player/presentation/cubit/player_detail_cubit.dart';
import 'package:nhl_app/features/player/presentation/cubit/player_detail_state.dart';

class PlayerDetailArgs {
  const PlayerDetailArgs({
    required this.playerId,
    this.fallbackName,
    this.fallbackNumber,
    this.fallbackPosition,
  });

  final int playerId;
  final String? fallbackName;
  final String? fallbackNumber;
  final String? fallbackPosition;

  String get label => (fallbackName == null || fallbackName!.isEmpty)
      ? 'Player'
      : fallbackName!;
}

class PlayerDetailPage extends StatelessWidget {
  const PlayerDetailPage({super.key, required this.args});

  final PlayerDetailArgs args;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = getIt<PlayerDetailCubit>();
        if (args.playerId > 0) {
          cubit.load(args.playerId);
        }
        return cubit;
      },
      child: Column(
        children: [
          PageHeader(title: 'Player Page'),
          Expanded(
            child: BlocBuilder<PlayerDetailCubit, PlayerDetailState>(
              builder: (context, state) {
                if (args.playerId <= 0) {
                  return const Center(
                    child: Text(
                      'Player data is unavailable. Please return and pick a player again.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }
                if (state is PlayerDetailLoading ||
                    state is PlayerDetailInitial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is PlayerDetailError) {
                  return Center(
                    child: Text(
                      state.message,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                final detail = (state as PlayerDetailLoaded).detail;
                return ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 20,
                  ),
                  children: [
                    _InfoField(
                      label: 'Name',
                      value: _fallbackText(
                        detail.name,
                        args.fallbackName,
                        'Player',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _InfoField(
                      label: 'Number',
                      value: _fallbackText(
                        detail.number,
                        args.fallbackNumber,
                        '--',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _InfoField(
                      label: 'Position',
                      value: _fallbackText(
                        detail.position,
                        args.fallbackPosition,
                        '-',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _InfoField(
                      label: 'Shoots',
                      value: detail.shoots.isEmpty ? '-' : detail.shoots,
                    ),
                    const SizedBox(height: 12),
                    _InfoField(
                      label: 'DOB',
                      value: detail.dob.isEmpty ? '-' : detail.dob,
                    ),
                    const SizedBox(height: 12),
                    _InfoField(
                      label: 'Country',
                      value: detail.country.isEmpty ? '-' : detail.country,
                    ),
                    const SizedBox(height: 24),
                    const _SectionTitle('Stats Table'),
                    const SizedBox(height: 12),
                    _StatsTable(stats: detail.stats),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

String _fallbackText(String primary, String? fallback, String defaultText) {
  if (primary.isNotEmpty) return primary;
  if (fallback != null && fallback.isNotEmpty) return fallback;
  return defaultText;
}

class _InfoField extends StatefulWidget {
  const _InfoField({required this.label, required this.value});
  final String label;
  final String value;

  static const Color _labelColor = Color.fromRGBO(77, 127, 169, 1);
  static const Color _fieldColor = Color.fromRGBO(35, 86, 130, 1);

  @override
  State<_InfoField> createState() => _InfoFieldState();
}

class _InfoFieldState extends State<_InfoField> {
  late String _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
  }

  @override
  void didUpdateWidget(covariant _InfoField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _currentValue = widget.value;
    }
  }

  void _clearField() {
    if (_currentValue.isEmpty) return;
    setState(() {
      _currentValue = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.label}:',
          style: const TextStyle(
            color: _InfoField._labelColor,
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _InfoField._fieldColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _currentValue,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _clearField,
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: _currentValue.isEmpty
                      ? Colors.white.withValues(alpha: .25)
                      : Colors.white.withValues(alpha: .8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsTable extends StatelessWidget {
  const _StatsTable({required this.stats});
  final PlayerSeasonStats stats;

  static const Color _bg = CustomColors.backgroundColor;
  static const Color _line = Color.fromRGBO(89, 143, 195, 1);
  static const headers = ['GP', 'G', 'A', 'P', '+/-', 'PIM', 'TOI/GP'];

  @override
  Widget build(BuildContext context) {
    final plus = stats.plusMinus > 0
        ? '+${stats.plusMinus}'
        : stats.plusMinus.toString();
    final values = [
      stats.gamesPlayed.toString(),
      stats.goals.toString(),
      stats.assists.toString(),
      stats.points.toString(),
      plus,
      stats.pim.toString(),
      stats.toiPerGame,
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: _bg),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(0.7),
            1: FlexColumnWidth(0.7),
            2: FlexColumnWidth(0.7),
            3: FlexColumnWidth(0.7),
            4: FlexColumnWidth(0.7),
            5: FlexColumnWidth(0.7),
            6: FlexColumnWidth(1.3),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          border: const TableBorder(
            horizontalInside: BorderSide(color: _line, width: .6),
            verticalInside: BorderSide(color: _line, width: 1),
          ),
          children: [
            TableRow(
              children: headers
                  .map((h) => _cell(h, head: true, align: TextAlign.center))
                  .toList(),
            ),
            TableRow(
              children: values
                  .map((v) => _cell(v, head: false, align: TextAlign.center))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell(String text, {required bool head, required TextAlign align}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: align,
        style: TextStyle(
          color: head ? const Color.fromRGBO(89, 143, 195, 1) : Colors.white,
          fontWeight: head ? FontWeight.w700 : FontWeight.w800,
          fontSize: head ? 14 : 16,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
