import 'package:go_router/go_router.dart';
import 'package:nhl_app/core/router/routes.dart';
import 'package:nhl_app/features/shell_scaffold/presentation/shell_scaffold.dart';
import 'package:nhl_app/features/upcoming/presentation/pages/upcoming_page.dart';
import 'package:nhl_app/features/standings/presentation/pages/standings_page.dart';
import 'package:nhl_app/features/favorites/presentation/pages/favorites_page.dart';
import 'package:nhl_app/features/predictor/domain/entities/predictor_match.dart';
import 'package:nhl_app/features/predictor/presentation/pages/predictor_page.dart';
import 'package:nhl_app/features/predictor/presentation/pages/predictor_scoreboard_page.dart';
import 'package:nhl_app/features/teams/presentation/pages/teams_page.dart';
import 'package:nhl_app/features/teams/presentation/pages/team_detail_page.dart';
import 'package:nhl_app/features/game_center/presentation/pages/game_center_page.dart';
import 'package:nhl_app/features/matches/domain/entities/match_entity.dart';
import 'package:nhl_app/features/splash/presentation/pages/splash_page.dart';
import 'package:nhl_app/features/player/presentation/pages/player_detail_page.dart';
import 'package:nhl_app/features/settings/presentation/pages/settings_page.dart';
import 'package:nhl_app/features/welcome/presentation/pages/welcome_page.dart';

class AppRouter {
  AppRouter();

  late final router = GoRouter(
    initialLocation: Routes.shell,
    routes: [
      GoRoute(
        path: Routes.settings,
        pageBuilder: (c, s) => const NoTransitionPage(child: SettingsPage()),
      ),
      GoRoute(
        path: Routes.welcome,
        pageBuilder: (c, s) => const NoTransitionPage(child: WelcomePage()),
      ),
      GoRoute(
        path: Routes.shell,
        name: 'splash',
        pageBuilder: (c, s) => const NoTransitionPage(child: SplashPage()),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ShellScaffold(
            navigationShell: navigationShell,
          );
        },
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.upcoming,
              name: 'upcoming',
              pageBuilder: (c, s) => const NoTransitionPage(child: UpcomingPage()),
            ),
            GoRoute(
              path: '/gamecenter',
              name: 'game_center',
              pageBuilder: (c, s) {
                final args = s.extra is GameCenterArgs
                    ? s.extra as GameCenterArgs
                    : GameCenterArgs(
                        gameId: '0',
                        homeTeam: 'Home',
                        awayTeam: 'Away',
                        status: MatchStatus.upcoming,
                        startTime: DateTime.now(),
                );
            return NoTransitionPage(child: GameCenterPage(args: args));
              },
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.standings,
              name: 'standings',
              pageBuilder: (c, s) => const NoTransitionPage(child: StandingsPage()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.teams,
              name: 'teams',
              pageBuilder: (c, s) => const NoTransitionPage(child: TeamsPage()),
            ),
            GoRoute(
              path: '/teams/detail',
              name: 'team_detail',
              pageBuilder: (c, s) {
                final args = s.extra is TeamDetailArgs
                    ? s.extra as TeamDetailArgs
                    : const TeamDetailArgs(name: 'Team', division: '-', abbrev: 'XXX', logoUrl: null);
                return NoTransitionPage(child: TeamDetailPage(args: args));
              },
            ),
            GoRoute(
              path: '/teams/player',
              name: 'player_detail',
              pageBuilder: (c, s) {
                final args = s.extra is PlayerDetailArgs
                    ? s.extra as PlayerDetailArgs
                    : const PlayerDetailArgs(playerId: 0);
                return NoTransitionPage(child: PlayerDetailPage(args: args));
              },
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.favorites,
              name: 'favorites',
              pageBuilder: (c, s) => const NoTransitionPage(child: FavoritesPage()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.predictor,
              name: 'predictor',
              pageBuilder: (c, s) {
                final match = s.extra is PredictorMatch ? s.extra as PredictorMatch : null;
                return NoTransitionPage(child: PredictorPage(match: match));
              },
            ),
            GoRoute(
              path: Routes.predictorScoreboard,
              name: 'predictor_scoreboard',
              pageBuilder: (c, s) => const NoTransitionPage(child: PredictorScoreboardPage()),
            ),
          ]),
        ],
      ),
    ],
  );

}


