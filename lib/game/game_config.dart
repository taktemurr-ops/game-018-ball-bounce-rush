import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/arcade_stage.dart';
import '../app/game_api.dart';
import '../app/services/audio.dart';
import '../core/arcade.dart';
import '../core/game_rules.dart';
import 'bounce_engine.dart';
import 'rules.dart';

void paintBounce(Canvas c, ArcadeSim sim, ArcadePalette p, double t) {
  final s = sim as BounceSim;
  double sx(double trackX) => trackX - s.dist;
  // far hills
  final hill = Paint()..color = Colors.white10;
  for (var i = 0; i < 6; i++) {
    final x = (i * 320 - s.dist * 0.3) % 1900 - 300;
    c.drawCircle(Offset(x, kGroundY + 120), 260, hill);
  }
  final ground = Paint()..color = p.piece(3);
  // ground with pits cut out
  final pits = s.obs.where((o) => o.kind == kPit).toList()..sort((a, b) => a.x.compareTo(b.x));
  var from = 0.0;
  for (final o in pits) {
    final a = sx(o.x), b = sx(o.end);
    if (b < 0 || a > kWorldW) continue;
    if (a > from) c.drawRect(Rect.fromLTRB(from, kGroundY, a, kWorldH), ground);
    from = math.max(from, b);
  }
  if (from < kWorldW) c.drawRect(Rect.fromLTRB(from, kGroundY, kWorldW, kWorldH), ground);
  c.drawRect(const Rect.fromLTRB(0, kGroundY, kWorldW, kGroundY + 10), Paint()..color = Colors.white24);
  for (final o in s.obs) {
    final a = sx(o.x), b = sx(o.end);
    if (b < -50 || a > kWorldW + 50) continue;
    switch (o.kind) {
      case kSpike:
        final path = Path();
        final n = (o.w / 40).ceil();
        final w = o.w / n;
        for (var i = 0; i < n; i++) {
          path
            ..moveTo(a + i * w, kGroundY)
            ..lineTo(a + i * w + w / 2, kGroundY - kSpikeH)
            ..lineTo(a + (i + 1) * w, kGroundY)
            ..close();
        }
        c.drawPath(path, Paint()..color = const Color(0xFFE63946));
      case kBar:
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(a, kBarBottom - 60, b, kBarBottom), const Radius.circular(10)),
            Paint()..color = const Color(0xFF8D99AE));
        c.drawRect(Rect.fromLTRB(a + 10, 0, a + 22, kBarBottom - 60), Paint()..color = Colors.white24);
        c.drawRect(Rect.fromLTRB(b - 22, 0, b - 10, kBarBottom - 60), Paint()..color = Colors.white24);
      case kBox:
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(a, kGroundY - kBoxH, b, kGroundY), const Radius.circular(8)),
            Paint()..color = p.piece(1));
      case kRing:
        if (!o.taken) {
          c.drawOval(Rect.fromCenter(center: Offset(a + 30, kGroundY - 220), width: 46, height: 80),
              Paint()
                ..color = const Color(0xFFFFD60A)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 9);
        }
    }
  }
  if (s.level.length > 0) {
    final fx = sx(s.level.length + kBallX);
    if (fx < kWorldW + 50) {
      c.drawRect(Rect.fromLTWH(fx, kGroundY - 320, 10, 320), Paint()..color = Colors.white);
      c.drawRect(Rect.fromLTWH(fx + 10, kGroundY - 320, 90, 60), Paint()..color = const Color(0xFF06D6A0));
    }
  }
  // ball with squash
  final sq = s.squash;
  final blink = s.shield > 0 && (s.ticks ~/ 5).isOdd;
  final o = Offset(kBallX, s.y + sq * 8);
  c.save();
  c.translate(o.dx, o.dy);
  c.rotate(s.dist / kBallR);
  c.drawOval(Rect.fromCenter(center: Offset.zero, width: kBallR * 2 * (1 + sq * 0.25), height: kBallR * 2 * (1 - sq * 0.25)),
      Paint()..color = blink ? Colors.white38 : p.piece(0));
  c.drawLine(const Offset(-kBallR + 6, 0), const Offset(kBallR - 6, 0), Paint()
    ..color = Colors.white54
    ..strokeWidth = 6);
  c.restore();
}

Sfx? bounceSound(ArcadeSim sim) => switch ((sim as BounceSim).lastEvent) {
      1 => Sfx.tap,
      2 => Sfx.coin,
      _ => null,
    };

final gameConfig = GameConfig(
  gameId: 'game-018-ball-bounce-rush',
  title: const ['Zıplayan Top Koşusu', 'Ball Bounce Rush', 'Hüpfball-Rennen', 'Carrera Rebote', 'Course Rebond'],
  tagline: const ['Zıpla, sek, bayrağa koş!', 'Jump, bounce, rush to the flag!', 'Springen, hüpfen, zur Flagge!', '¡Salta, rebota, corre a la bandera!', 'Sautez, rebondissez, foncez !'],
  seedColor: const Color(0xFFEF233C),
  icon: Icons.sports_volleyball,
  rules: BounceRules(),
  buildPlay: (ctx) => ArcadeStage(
    ctx: ctx,
    create: () => BounceSim((ctx.generated as GeneratedLevel<BounceLevel>).puzzle),
    paint: paintBounce,
    sound: bounceSound,
    howTo: const [
      'Zıplamak için dokun. Dikenlerin ve çukurların üstünden atla!',
      'Tap to jump over spikes and pits!',
      'Tippen zum Springen!',
      '¡Toca para saltar!',
      'Touchez pour sauter !',
    ],
  ),
  tutorial: const [
    TutorialStep(Icons.touch_app, [
      'Dokun ya da boşluk tuşu: zıpla. Bazı bölümlerde havada ikinci zıplama var.',
      'Tap or space: jump. Some levels allow a double jump.',
      'Tippen oder Leertaste: springen.',
      'Toca o espacio: saltar.',
      'Toucher ou espace : sauter.',
    ]),
    TutorialStep(Icons.warning, [
      'Alçak tavanların altında zıplama! Kutuların üstüne çık.',
      'Do not jump under low ceilings! Hop onto boxes.',
      'Nicht unter Decken springen!',
      '¡No saltes bajo techos bajos!',
      'Ne sautez pas sous les plafonds bas !',
    ]),
    TutorialStep(Icons.flag, [
      'Halkaları topla ve bayrağa ulaş.',
      'Collect rings and reach the flag.',
      'Sammle Ringe, erreiche die Flagge.',
      'Recoge anillos y llega a la bandera.',
      'Ramassez les anneaux, atteignez le drapeau.',
    ]),
  ],
);
