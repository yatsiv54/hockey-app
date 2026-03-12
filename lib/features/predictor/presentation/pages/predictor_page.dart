import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:nhl_app/core/router/routes.dart';
import 'package:nhl_app/core/widgets/page_header.dart';
import 'package:nhl_app/features/matches/domain/entities/match_entity.dart';
import 'package:nhl_app/features/predictor/data/prediction_storage.dart';
import 'package:nhl_app/features/predictor/domain/entities/prediction_record.dart';
import 'package:nhl_app/features/predictor/domain/entities/predictor_match.dart';

class PredictorPage extends StatefulWidget {
  const PredictorPage({super.key, this.match});

  final PredictorMatch? match;

  @override
  State<PredictorPage> createState() => _PredictorPageState();
}

enum _WinnerChoice { home, draw, away }

class _PredictorPageState extends State<PredictorPage> {
  final _goalsController = TextEditingController();
  final _storage = PredictionStorage();
  _WinnerChoice? _winner = _WinnerChoice.draw;
  bool _overtime = false;
  String _exactScore = '';
  bool _submitting = false;
  PredictorMatch? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.match;
  }

  @override
  void didUpdateWidget(covariant PredictorPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.match != oldWidget.match) {
      setState(() {
        _selected = widget.match;
      });
    }
  }

  @override
  void dispose() {
    _goalsController.dispose();
    super.dispose();
  }

  PredictorMatch? get _match => _selected;

  bool get _hasMatch =>
      _match != null &&
      (_match!.status == MatchStatus.upcoming ||
          _match!.status == MatchStatus.live);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PageHeader(
          title: 'Puck Predictor —\nGuess the Game!',
          showSettings: true,
          bottomGap: 8,
          actions: [
            IconButton(
              onPressed: _openScoreboard,
              icon: const Icon(Icons.leaderboard_outlined, color: Colors.white),
            ),
          ],
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: _hasMatch ? _buildForm(context) : _buildPlaceholder(),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF143455),
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: Alignment.center,
      child: const Text(
        'Select a match in Home',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final match = _match!;
    return Container(
      decoration: const BoxDecoration(
        color: Color.fromRGBO(255, 255, 255, 0.1),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _MatchCard(match: match),
          const SizedBox(height: 15),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: _SectionLabel('Winner'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: _ChoiceBar(
              items: const ['Home', 'Draw', 'Away'],
              activeIndex: _winner == _WinnerChoice.home
                  ? 0
                  : _winner == _WinnerChoice.draw
                      ? 1
                      : 2,
              onTap: (index) {
                setState(() {
                  _winner = _WinnerChoice.values[index];
                });
              },
            ),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: _SectionLabel('Overtime'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: _ChoiceBar(
              items: const ['Yes', 'No'],
              activeIndex: _overtime ? 0 : 1,
              onTap: (index) {
                setState(() => _overtime = index == 0);
              },
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: _TextField(
              label: 'Total Goals',
              controller: _goalsController,
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: _ExactScoreDropdown(
              value: _exactScore,
              onChanged: (value) => setState(() => _exactScore = value ?? ''),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: _SecondaryButton(
              text: 'Cancel',
              onTap: () {
                setState(() {
                  _winner = _WinnerChoice.draw;
                  _overtime = false;
                  _goalsController.clear();
                  _exactScore = '';
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: _ScoreboardButton(
              text: 'My scoreboard',
              onTap: _openScoreboard,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: _PrimaryButton(
              text: _submitting ? 'Submitting...' : 'Submit Prediction',
              disabled: _submitting,
              onTap: _submitting ? null : _submitPrediction,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _submitPrediction() async {
    final match = _match;
    if (match == null) {
      _showMessage('Select a match first');
      return;
    }
    final winner = _winner;
    final goalsText = _goalsController.text.trim();
    if (winner == null || goalsText.isEmpty) {
      _showMessage('Please fill in all fields');
      return;
    }
    final goals = int.tryParse(goalsText);
    if (goals == null) {
      _showMessage('Enter a valid total goals number');
      return;
    }
    if (_exactScore.isEmpty) {
      _showMessage('Select an exact score');
      return;
    }
    final record = PredictionRecord(
      matchId: match.id,
      homeTeam: match.homeTeam,
      awayTeam: match.awayTeam,
      homeAbbrev: match.homeAbbrev,
      awayAbbrev: match.awayAbbrev,
      winner: winner.name,
      overtime: _overtime,
      totalGoals: goals,
      exactScore: _exactScore,
      timestamp: DateTime.now(),
      status: match.status,
      matchStart: match.startTime,
    );
    setState(() => _submitting = true);
    await _storage.append(record);
    setState(() => _submitting = false);
    _resetForm();
    if (mounted) {
      _showMessage('Prediction saved!');
    }
  }

  void _resetForm() {
    setState(() {
      _winner = _WinnerChoice.draw;
      _overtime = false;
      _goalsController.clear();
      _exactScore = '';
      _selected = null;
    });
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _openScoreboard() {
    context.push(Routes.predictorScoreboard);
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match});
  final PredictorMatch match;

  @override
  Widget build(BuildContext context) {
    final dateText = match.startTime != null
        ? '${match.startTime!.day.toString().padLeft(2, '0')}.${match.startTime!.month.toString().padLeft(2, '0')}.${match.startTime!.year}'
        : '--';
    final timeText = match.startTime != null
        ? '${match.startTime!.hour.toString().padLeft(2, '0')}:${match.startTime!.minute.toString().padLeft(2, '0')}'
        : '--';

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Positioned(
                top: 5,
                child: Text(
                  dateText,
                  style: const TextStyle(
                    color: Color.fromRGBO(36, 110, 171, 1),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Positioned(
                top: 22,
                child: Text(
                  timeText,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 15),
                child: Row(
                  children: [
                    Expanded(
                      child: _MatchLogo(
                        name: match.homeTeam,
                        logo: match.homeLogo,
                      ),
                    ),
                    SizedBox(width: 30),
                    Expanded(
                      child: _MatchLogo(
                        name: match.awayTeam,
                        logo: match.awayLogo,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2E6AA0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Venue', style: TextStyle(fontSize: 15)),
                Text(
                  match.venue ?? 'TBD',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchLogo extends StatelessWidget {
  const _MatchLogo({required this.name, required this.logo});

  final String name;
  final String? logo;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          SizedBox(height: 80, width: 120, child: _buildLogo()),
          SizedBox(
            width: 130,
            child: Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                height: 1,
                color: Colors.black87,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    if (logo == null || logo!.isEmpty) {
      return const _LogoPlaceholder();
    }

    final uri = Uri.tryParse(logo!);
    final path = uri?.path.toLowerCase() ?? logo!.toLowerCase();
    final isSvg = path.endsWith('.svg');

    if (isSvg) {
      return SvgPicture.network(
        logo!,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => const _LogoPlaceholder(),
      );
    }

    return Image.network(
      logo!,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const _LogoPlaceholder(),
    );
  }
}

class _LogoPlaceholder extends StatelessWidget {
  const _LogoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(color: Colors.black12, shape: BoxShape.circle),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ChoiceBar extends StatelessWidget {
  const _ChoiceBar({
    required this.items,
    required this.activeIndex,
    required this.onTap,
  });

  final List<String> items;
  final int activeIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                    color: i == activeIndex
                        ? const Color.fromRGBO(136, 170, 47, 1)
                        : const Color.fromRGBO(67, 113, 157, 1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    items[i],
                    style: TextStyle(
                      fontSize: 19,
                      color: i == activeIndex
                          ? Colors.white
                          : Color.fromRGBO(105, 149, 191, 1),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            if (i != items.length - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.label,
    required this.controller,
    this.keyboardType,
  });
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label),
        SizedBox(
          height: 35,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.only(left: 8),
              filled: true,
              fillColor: Color.fromRGBO(67, 113, 157, 1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(5)),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
          ),
        ),
      ],
    );
  }
}

class _ExactScoreDropdown extends StatelessWidget {
  const _ExactScoreDropdown({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = <String>[''] +
        [
          for (var home = 0; home <= 9; home++)
            for (var away = 0; away <= 9; away++) '$home-$away',
        ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Exact Score'),
        Container(
          height: 35,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Color.fromRGBO(67, 113, 157, 1),
            borderRadius: BorderRadius.circular(5),
          ),
          child: DropdownButton<String>(
            padding: EdgeInsets.only(left: 3),
            iconSize: 36,
            value: value.isEmpty ? null : value,
            hint: const Text(
              'Select exact score',
              style: TextStyle(color: Colors.white70),
            ),
            dropdownColor: const Color(0xFF1F4F7C),
            isExpanded: true,
            underline: const SizedBox.shrink(),
            iconEnabledColor: Colors.white,
            style: const TextStyle(color: Colors.white),
            items: options
                .map(
                  (e) => DropdownMenuItem(
                    value: e.isEmpty ? null : e,
                    child: Text(
                      e.isEmpty ? '--' : e,
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18),
                    ),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.text,
    required this.onTap,
    this.filled = false,
  });

  final String text;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled
              ? const Color(0xFF326CA4)
              : Color.fromRGBO(255, 255, 255, 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: filled ? Colors.white : Colors.white30,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _ScoreboardButton extends StatelessWidget {
  const _ScoreboardButton({
    required this.text,
    required this.onTap,
    this.filled = false,
  });

  final String text;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: BoxBorder.all(
            color: Color.fromRGBO(136, 170, 47, 1),
            width: 1.3,
          ),
          color: Color.fromRGBO(255, 255, 255, 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: filled ? Colors.white : Colors.white30,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.text,
    required this.onTap,
    this.disabled = false,
  });
  final String text;
  final VoidCallback? onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Color.fromRGBO(136, 170, 47, 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
