import 'package:flutter_test/flutter_test.dart';
import 'package:game_018_ball_bounce_rush/game/bounce_game.dart';

void main() {
  test('initial state and reset', () {
    final g = BounceGame();
    expect(g.lives, 3);
    g.score = 7; g.lives = 1;
    g.reset();
    expect(g.score, 0); expect(g.lives, 3);
  });
  test('invalid timestep never changes physics', () {
    final g = BounceGame();
    g.tick(-1); g.tick(double.nan);
    expect(g.x, 0.5); expect(g.y, 0.5);
  });
  test('paddle is clamped and nonfinite input ignored', () {
    final g = BounceGame();
    g.setPaddle(-10); expect(g.paddle, 0.13);
    g.setPaddle(10); expect(g.paddle, 0.87);
    g.setPaddle(double.nan); expect(g.paddle, 0.87);
  });
  test('paused and game over freeze movement', () {
    final g = BounceGame();
    g.paused = true; g.tick(0.1);
    expect(g.x, 0.5);
    g.paused = false; g.lives = 0; g.tick(0.1);
    expect(g.x, 0.5);
  });
  test('ball advances during active play', () {
    final g = BounceGame();
    g.tick(0.1);
    expect(g.x, greaterThan(0.5));
  });
}
