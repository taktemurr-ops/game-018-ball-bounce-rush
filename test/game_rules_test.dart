import 'package:flutter_test/flutter_test.dart';
import 'package:game_018_ball_bounce_rush/core/arcade.dart';
import 'package:game_018_ball_bounce_rush/core/level_plan.dart';
import 'package:game_018_ball_bounce_rush/game/bounce_engine.dart';
import 'package:game_018_ball_bounce_rush/game/rules.dart';

void main() {
  final rules = BounceRules();
  final planner = LevelPlanner(gameId: rules.gameId, optionalMechanics: rules.optionalMechanics);

  test('tap jumps, gravity brings the ball back to the ground', () {
    final s = BounceSim(rules.build(planner.spec(1)).puzzle);
    s.obs.clear();
    s.nextAt = 1e9;
    s.tick(const ArcadeInput(tap: true));
    expect(s.grounded, isFalse);
    for (var i = 0; i < 80; i++) {
      s.tick(ArcadeInput.idle);
    }
    expect(s.grounded, isTrue);
    expect(s.jumps, 1);
  });

  test('running into a spike costs a life', () {
    final s = BounceSim(rules.build(planner.spec(1)).puzzle);
    s.obs
      ..clear()
      ..add(Obstacle(kSpike, s.ballTrackX + 200, 80));
    s.nextAt = 1e9;
    for (var i = 0; i < 80; i++) {
      s.tick(ArcadeInput.idle);
    }
    expect(s.lives, 2);
  });

  test('a ceiling bar does not hurt a grounded ball', () {
    final s = BounceSim(rules.build(planner.spec(1)).puzzle);
    s.obs
      ..clear()
      ..add(Obstacle(kBar, s.ballTrackX + 100, 300));
    s.nextAt = 1e9;
    for (var i = 0; i < 100; i++) {
      s.tick(ArcadeInput.idle);
    }
    expect(s.lives, 3);
  });
}
