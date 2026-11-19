import 'dart:math' as math;

import '../core/arcade.dart';
import '../core/level_plan.dart';

/// Obstacle kinds.
const int kSpike = 0, kPit = 1, kBar = 2, kBox = 3, kRing = 4;

class BounceLevel {
  final ArcadeMeta meta;
  final double length; // 0 = endless
  final double speed;
  final bool doubleJump;
  final bool ceilings;
  final bool platforms;
  final bool rings;

  const BounceLevel({
    required this.meta,
    required this.length,
    required this.speed,
    required this.doubleJump,
    required this.ceilings,
    required this.platforms,
    required this.rings,
  });
}

BounceLevel generateBounceLevel(LevelSpec spec) {
  final m = ArcadeMeta.of(spec);
  final d = spec.difficulty;
  return BounceLevel(
    meta: m,
    length: m.goal ? 4000.0 + d * 900 : 0,
    speed: 7.5 + d * 0.35 + (spec.has('fast') ? 1.5 : 0),
    doubleJump: spec.has('double'),
    ceilings: spec.has('ceilings') || d >= 6,
    platforms: spec.has('platforms') || d >= 4,
    rings: spec.has('rings') || !m.goal,
  );
}

const double kBallX = 300;
const double kBallR = 34;
const double kGroundY = 1300;
const double kGravity = 0.9;
const double kJumpV = -20;
const double kSpikeH = 80;
const double kBoxH = 140;
const double kBarBottom = kGroundY - 170;

class Obstacle {
  final int kind;
  final double x; // track coordinate of the left edge
  final double w;
  bool taken = false; // rings
  Obstacle(this.kind, this.x, this.w);
  double get end => x + w;
}

class BounceSim extends ArcadeSim {
  final BounceLevel level;
  double dist = 0; // track position of the screen's left edge
  double y = kGroundY - kBallR; // ball center
  double vy = 0;
  bool grounded = true;
  bool usedDouble = false;
  int coyote = 0, buffer = 0;
  final List<Obstacle> obs = [];
  double nextAt = 1400;
  int jumps = 0, ringsGot = 0;
  double squash = 0; // visual
  int lastEvent = 0; // 1 jump, 2 ring, 3 land

  BounceSim(this.level) : super(level.meta) {
    _fill();
  }

  double get speed => level.speed * (1 + (meta.goal ? 0 : math.min(0.6, dist / 40000)));
  double get ballTrackX => dist + kBallX;

  void _fill() {
    while (nextAt < dist + kWorldW * 2.5) {
      final v = speed;
      final r = rng.nextInt(10);
      Obstacle o;
      if (level.platforms && r < 2) {
        o = Obstacle(kBox, nextAt, 420 + rng.nextDouble() * 240);
      } else if (level.ceilings && r < 4) {
        o = Obstacle(kBar, nextAt, 200 + rng.nextDouble() * 200);
      } else if (r < 7) {
        o = Obstacle(kSpike, nextAt, 60 + rng.nextDouble() * 80);
      } else {
        o = Obstacle(kPit, nextAt, 120 + rng.nextDouble() * (v * 44 * 0.5 - 120));
      }
      obs.add(o);
      if (level.rings && o.kind != kBar && rng.chance(0.5)) {
        obs.add(Obstacle(kRing, o.x + o.w / 2 - 30, 60));
      }
      nextAt = o.end + v * 55 + rng.nextDouble() * v * 30;
    }
  }

  bool get onBox {
    for (final o in obs) {
      if (o.kind == kBox && ballTrackX + kBallR * 0.6 > o.x && ballTrackX - kBallR * 0.6 < o.end) return true;
    }
    return false;
  }

  bool get overPit {
    for (final o in obs) {
      if (o.kind == kPit && ballTrackX > o.x + kBallR * 0.5 && ballTrackX < o.end - kBallR * 0.5) return true;
    }
    return false;
  }

  void _jump() {
    vy = kJumpV;
    grounded = false;
    coyote = 0;
    jumps++;
    lastEvent = 1;
    squash = 1;
  }

  @override
  void update(ArcadeInput input) {
    lastEvent = 0;
    final press = input.tap || input.swipe == 0;
    if (press) buffer = 6;
    if (buffer > 0) {
      if (grounded || coyote > 0) {
        _jump();
        buffer = 0;
      } else if (level.doubleJump && !usedDouble && press) {
        vy = kJumpV * 0.8;
        usedDouble = true;
        jumps++;
        buffer = 0;
        lastEvent = 1;
      } else {
        buffer--;
      }
    }
    dist += speed;
    if (squash > 0) squash = math.max(0, squash - 0.08);
    // vertical
    final floor = onBox ? kGroundY - kBoxH : (overPit ? 1e9 : kGroundY);
    if (!grounded) {
      vy += kGravity;
      y += vy;
      if (vy > 0 && y + kBallR >= floor && y + kBallR - vy <= floor + 1) {
        y = floor - kBallR;
        vy = 0;
        grounded = true;
        usedDouble = false;
        lastEvent = 3;
        squash = 0.6;
      }
    } else if (y + kBallR < floor - 1 || floor > 1e8) {
      // Walked off a box or into a pit.
      grounded = false;
      coyote = 6;
    } else {
      y = floor - kBallR;
    }
    if (coyote > 0 && !grounded) coyote--;
    _collide();
    if (y > kGroundY + 260) {
      if (meta.zen) {
        _respawnAhead();
      } else {
        hit();
        if (!over && !dead) _respawnAhead();
      }
    }
    score = (dist / 10).floor() + ringsGot * 20;
    if (level.length > 0 && dist >= level.length) win();
    obs.removeWhere((o) => o.end < dist - 100);
    _fill();
  }

  void _collide() {
    final bx = ballTrackX;
    for (final o in obs) {
      if (o.end < bx - kBallR || o.x > bx + kBallR) continue;
      switch (o.kind) {
        case kRing:
          if (!o.taken && y < kGroundY - 150) {
            o.taken = true;
            ringsGot++;
            lastEvent = 2;
          }
        case kSpike:
          if (y + kBallR > kGroundY - kSpikeH + 8) _hurt();
        case kBar:
          if (y - kBallR < kBarBottom) _hurt();
        case kBox:
          // Side hit: entering the box below its top.
          if (bx + kBallR * 0.8 >= o.x && bx < o.x + 10 && y + kBallR > kGroundY - kBoxH + 12) _hurt();
      }
    }
  }

  void _hurt() {
    if (shield > 0 || meta.zen) return;
    hit();
    if (!over) _respawnAhead();
  }

  /// Puts the ball safely after the obstacle that hit it.
  void _respawnAhead() {
    final bx = ballTrackX;
    for (final o in obs) {
      if (o.kind == kRing) continue;
      if (o.end >= bx - kBallR * 2 && o.x <= bx + kBallR * 2) dist = o.end + 40 - kBallX + kBallR;
    }
    y = kGroundY - kBallR;
    vy = 0;
    grounded = true;
    usedDouble = false;
  }

  @override
  void onLifeLost() {}

  @override
  double get progress => level.length == 0 ? 0 : dist / level.length;

  @override
  String get goalText => level.length == 0 ? '${(dist / 100).floor()}m' : '${(progress * 100).clamp(0, 100).floor()}%';

  @override
  Map<String, int> get stats => {'jumps': jumps, 'rings': ringsGot, 'distance_m': (dist / 100).floor()};

  @override
  int get stars => lifeStars(this, 3);
}

/// Autopilot: jumps in the right window before spikes, pits and boxes,
/// never under a ceiling bar.
ArcadeInput bounceBot(ArcadeSim sim) {
  final s = sim as BounceSim;
  final v = s.speed;
  final front = s.ballTrackX + kBallR;
  if (!s.grounded) return ArcadeInput.idle;
  for (final o in s.obs) {
    if (o.kind == kRing) continue;
    final dx = o.x - front;
    if (o.end < s.ballTrackX) continue;
    if (o.kind == kBar) {
      if (dx < v * 50) return ArcadeInput.idle; // stay low
      continue;
    }
    if (o.kind == kBox && s.onBox) continue;
    final lo = o.kind == kBox ? v * 11 : v * 4.4;
    final hi = o.kind == kBox ? v * 15 : v * 7;
    if (dx >= lo && dx <= hi) return const ArcadeInput(tap: true, down: true, x: 500, y: 800);
    if (dx > hi) break;
  }
  return ArcadeInput.idle;
}
