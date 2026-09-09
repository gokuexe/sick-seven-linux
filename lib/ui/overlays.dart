import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../engine.dart';
import '../model.dart';
import '../sfx.dart';
import '../theme.dart';

/// Pregunta modal. Cuando trae segundos es una ventana de reacción: la barra
/// se vacía y va sonando el tick, así la urgencia se siente sin leer nada.
class ChoiceOverlay extends StatefulWidget {
  final ChoiceRequest request;
  final void Function(Object? value) onPick;

  const ChoiceOverlay({
    super.key,
    required this.request,
    required this.onPick,
  });

  @override
  State<ChoiceOverlay> createState() => _ChoiceOverlayState();
}

class _ChoiceOverlayState extends State<ChoiceOverlay>
    with SingleTickerProviderStateMixin {
  AnimationController? _timer;
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..forward();
  int _lastTick = -1;

  @override
  void initState() {
    super.initState();
    final secs = widget.request.seconds;
    if (secs != null) {
      _timer = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: (secs * 1000).round()),
      )
        ..addListener(_onTick)
        ..forward();
      Sfx.i.thump();
    }
  }

  void _onTick() {
    if (!mounted) return;
    final secs = widget.request.seconds;
    if (secs == null) return;
    final left = (secs * (1 - _timer!.value)).ceil();
    if (left != _lastTick && left <= 5 && left > 0) {
      _lastTick = left;
      Sfx.i.play('tick', volume: 0.35);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _timer?.dispose();
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    final progress = _timer == null ? 1.0 : 1 - _timer!.value;

    return Positioned.fill(
      child: Container(
        color: const Color(0xE60A1219),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(22),
        child: FadeTransition(
          opacity: _enter,
          child: ScaleTransition(
            scale: Tween(begin: 0.92, end: 1.0).animate(
              CurvedAnimation(parent: _enter, curve: Curves.easeOutBack),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_timer != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        backgroundColor: SS.surface,
                        valueColor: AlwaysStoppedAnimation(
                          Color.lerp(SS.rojo, SS.mana, progress)!,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  Text(
                    r.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: SS.ink,
                    ),
                  ),
                  if (r.desc.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(r.desc, textAlign: TextAlign.center, style: SS.sub),
                  ],
                  const SizedBox(height: 16),
                  for (final o in r.options)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _OptionButton(
                        option: o,
                        onTap: () {
                          Sfx.i.tap();
                          widget.onPick(o.value);
                        },
                      ),
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

class _OptionButton extends StatelessWidget {
  final ChoiceOption option;
  final VoidCallback onTap;

  const _OptionButton({required this.option, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tint = option.tint == null
        ? null
        : SS.of(option.tint == CardColor.red);
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
          decoration: BoxDecoration(
            color: SS.surface,
            borderRadius: BorderRadius.circular(11),
            border: Border(
              top: const BorderSide(color: SS.line),
              right: const BorderSide(color: SS.line),
              bottom: const BorderSide(color: SS.line),
              left: BorderSide(color: tint ?? SS.line, width: tint == null ? 1 : 4),
            ),
          ),
          child: Text(
            option.label,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: SS.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// La carta que acaba de jugarse, en grande y al centro. Dura poco: es para
/// que sepas qué pasó sin tener que leer el registro.
class FlyingCard extends StatelessWidget {
  final String actor;
  final ActionCard card;
  final Animation<double> anim;

  const FlyingCard({
    super.key,
    required this.actor,
    required this.card,
    required this.anim,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: anim,
          builder: (context, _) {
            final t = anim.value;
            final scale = 0.72 + Curves.easeOutBack.transform(
                  t.clamp(0.0, 0.55) / 0.55,
                ) * 0.35;
            final opacity = t < 0.7 ? 1.0 : (1 - (t - 0.7) / 0.3);
            final dy = -18.0 - t * 26;
            return Center(
              child: Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, dy),
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                      decoration: BoxDecoration(
                        color: SS.surfaceUp,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: SS.mana, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(actor,
                              style: const TextStyle(
                                  fontSize: 11, color: SS.mute)),
                          const SizedBox(height: 4),
                          Text(
                            card.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: SS.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Pantalla final con papelitos. Solo aparece cuando ganás vos; si gana un bot
/// la misma pantalla va sin confeti.
class EndOverlay extends StatefulWidget {
  final String winner;
  final bool youWon;
  final VoidCallback onAgain;

  const EndOverlay({
    super.key,
    required this.winner,
    required this.youWon,
    required this.onAgain,
  });

  @override
  State<EndOverlay> createState() => _EndOverlayState();
}

class _EndOverlayState extends State<EndOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: const Color(0xF00A1219),
        child: Stack(
          children: [
            if (widget.youWon)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (context, _) =>
                      CustomPaint(painter: _ConfettiPainter(_c.value)),
                ),
              ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.youWon ? 'Ganaste' : '${widget.winner} gana',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: widget.youWon ? SS.win : SS.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('6 y 7, uno en cada carta.', style: SS.sub),
                  const SizedBox(height: 26),
                  GestureDetector(
                    onTap: widget.onAgain,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 34, vertical: 14),
                      decoration: BoxDecoration(
                        color: SS.mana,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Jugar otra',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2A1F05),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double t;
  _ConfettiPainter(this.t);

  static const _palette = [SS.rojo, SS.azul, SS.mana, SS.win];

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(11);
    final paint = Paint();
    for (var i = 0; i < 70; i++) {
      final x0 = rnd.nextDouble() * size.width;
      final delay = rnd.nextDouble() * 0.3;
      final speed = 0.7 + rnd.nextDouble() * 0.6;
      final local = ((t - delay) * speed).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final y = -30 + local * (size.height + 60);
      final x = x0 + math.sin(local * 7 + i) * 26;
      final w = 4.0 + rnd.nextDouble() * 5;
      final h = w * (1.4 + rnd.nextDouble());
      paint.color = _palette[i % _palette.length]
          .withValues(alpha: (1 - local * 0.55).clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(local * 9 + i);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w, height: h),
          const Radius.circular(1.5),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}
