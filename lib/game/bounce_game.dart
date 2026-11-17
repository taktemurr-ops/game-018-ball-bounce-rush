import 'dart:math';

class BounceGame {
  double x = 0.5, y = 0.5, vx = 0.37, vy = 0.28;
  double paddle = 0.5;
  int score = 0;
  int lives = 3;
  bool paused = false;
  bool get over => lives <= 0;
  void reset() {
    x = 0.5; y = 0.5; vx = 0.37; vy = 0.28;
    paddle = 0.5; score = 0; lives = 3; paused = false;
  }
  void setPaddle(double position) {
    if (!position.isFinite) return;
    paddle = position.clamp(0.13, 0.87).toDouble();
  }
  void tick(double dt) {
    if (paused || over || !dt.isFinite || dt <= 0) return;
    // Substeps prevent the ball tunneling through the paddle at low FPS.
    var remaining = min(dt, 0.25);
    while (remaining > 0) {
      final step = min(remaining, 0.008);
      remaining -= step;
      x += vx * step;
      y += vy * step;
      if (x < 0.035) { x = 0.035; vx = vx.abs(); }
      if (x > 0.965) { x = 0.965; vx = -vx.abs(); }
      if (y < 0.035) { y = 0.035; vy = vy.abs(); }
      if (vy > 0 && y >= 0.9 && y <= 0.95 && (x - paddle).abs() <= 0.15) {
        y = 0.9;
        vy = -vy.abs() * 1.025;
        vx = (vx + (x - paddle) * 0.25).clamp(-0.8, 0.8).toDouble();
        score++;
      }
      if (y > 1.03) {
        lives--;
        x = 0.5; y = 0.5; vx = 0.37; vy = 0.28;
        break;
      }
    }
  }
}
