import 'dart:async';
import 'package:flutter/material.dart';
import 'game/bounce_game.dart';

void main() => runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: BounceScreen()));

class BounceScreen extends StatefulWidget {
  const BounceScreen({super.key});
  @override
  State<BounceScreen> createState() => _BounceScreenState();
}
class _BounceScreenState extends State<BounceScreen> {
  final game = BounceGame();
  Timer? timer;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (mounted) setState(() => game.tick(0.016));
    });
  }
  @override
  void dispose() { timer?.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ball Bounce Rush')),
    body: SafeArea(child: Column(children: [
      Padding(padding: const EdgeInsets.all(12), child: Text(
        'Score: ${game.score}    Lives: ${game.lives}',
        style: Theme.of(context).textTheme.titleLarge)),
      Expanded(child: LayoutBuilder(builder: (context, bounds) => GestureDetector(
        onHorizontalDragUpdate: (details) => setState(() =>
          game.setPaddle((details.localPosition.dx / bounds.maxWidth))),
        onTapDown: (details) => setState(() =>
          game.setPaddle(details.localPosition.dx / bounds.maxWidth)),
        child: CustomPaint(size: Size(bounds.maxWidth, bounds.maxHeight),
          painter: _BouncePainter(game))))),
      if (game.over) const Padding(padding: EdgeInsets.all(8), child: Text('Game over!')),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        TextButton(onPressed: game.over ? null : () => setState(() => game.paused = !game.paused),
          child: Text(game.paused ? 'Resume' : 'Pause')),
        TextButton(onPressed: () => setState(game.reset), child: const Text('Restart')),
      ]),
      const Padding(padding: EdgeInsets.all(12),
        child: Text('Move the paddle by dragging or tapping. No ads required.')),
    ])),
  );
}
class _BouncePainter extends CustomPainter {
  final BounceGame game;
  _BouncePainter(this.game);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xff10192b));
    final ball = Paint()..color = Colors.orangeAccent;
    canvas.drawCircle(Offset(game.x * size.width, game.y * size.height), 10, ball);
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(game.paddle * size.width, 0.94 * size.height),
        width: size.width * 0.26, height: 14), radius: const Radius.circular(7)),
      Paint()..color = Colors.cyanAccent);
  }
  @override
  bool shouldRepaint(covariant _BouncePainter oldDelegate) => true;
}
