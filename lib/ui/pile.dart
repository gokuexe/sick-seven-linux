import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../model.dart';
import '../theme.dart';
import 'card_art.dart';

/// Una carta que ya se jugó y quedó sobre la mesa.
class PlayedEntry {
  final int seq;
  final String cardId;
  final String actor;
  final double dx;
  final double dy;
  final double rot;
  bool blocked;

  PlayedEntry({
    required this.seq,
    required this.cardId,
    required this.actor,
    required this.dx,
    required this.dy,
    required this.rot,
    this.blocked = false,
  });

  static final _rnd = math.Random();

  factory PlayedEntry.scattered(int seq, String cardId, String actor) =>
      PlayedEntry(
        seq: seq,
        cardId: cardId,
        actor: actor,
        dx: (_rnd.nextDouble() - 0.5) * 26,
        dy: (_rnd.nextDouble() - 0.5) * 16,
        rot: (_rnd.nextDouble() - 0.5) * 0.5,
      );
}

/// La carita de una carta jugada. Chica, con su ícono y su color, para que de
/// un vistazo sepas qué hay en la pila sin leer nada.
class MiniCard extends StatelessWidget {
  final String cardId;
  final bool blocked;

  const MiniCard({super.key, required this.cardId, this.blocked = false});

  @override
  Widget build(BuildContext context) {
    final v = visualFor(cardId);
    final card = kCards[cardId];

    return Container(
      width: 64,
      height: 86,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(SS.surfaceUp, v.color, 0.18)!,
            Color.lerp(SS.surface, v.color, 0.06)!,
          ],
        ),
        border: Border.all(
          color: blocked ? SS.rojo : v.color.withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 9,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: v.color.withValues(alpha: 0.22),
            blurRadius: 14,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon(v), size: 30, color: v.color),
              const SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  card?.name ?? '',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 8.5,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ),
          if (blocked)
            Positioned.fill(
              child: CustomPaint(painter: _BlockedPainter()),
            ),
        ],
      ),
    );
  }

  IconData icon(CardVisual v) => v.icon;
}

class _BlockedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = SS.rojo.withValues(alpha: 0.85)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(size.width * 0.16, size.height * 0.2),
        Offset(size.width * 0.84, size.height * 0.8),
        p);
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// La mesa. Las cartas caen desde arriba, golpean la pila y sueltan su efecto.
class PlayedPile extends StatefulWidget {
  final List<PlayedEntry> entries;
  final Widget? footer;

  const PlayedPile({super.key, required this.entries, this.footer});

  @override
  State<PlayedPile> createState() => _PlayedPileState();
}

class _PlayedPileState extends State<PlayedPile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  int _lastSeq = -1;

  @override
  void didUpdateWidget(covariant PlayedPile old) {
    super.didUpdateWidget(old);
    final top = widget.entries.isEmpty ? -1 : widget.entries.last.seq;
    if (top != _lastSeq) {
      _lastSeq = top;
      if (top >= 0) _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.entries;
    final visible = entries.length > 7
        ? entries.sublist(entries.length - 7)
        : entries;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const RadialGradient(
          center: Alignment.center,
          radius: 0.95,
          colors: [Color(0xFF1B3243), Color(0xFF101E29)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final c = _c.value;
            return Stack(
              alignment: Alignment.center,
              children: [
                const Positioned.fill(child: _Watermark()),

                // pila asentada
                for (var i = 0; i < visible.length; i++)
                  if (i < visible.length - 1)
                    _settled(visible[i], visible.length - 1 - i)
                  else
                    _landing(visible[i], c),

                if (visible.isEmpty)
                  Text(
                    'la mesa está limpia',
                    style: SS.sub.copyWith(
                        fontSize: 11, color: SS.mute.withValues(alpha: 0.5)),
                  ),

                // efecto de la última carta, por encima de todo
                if (visible.isNotEmpty && c > 0 && c < 1)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: CardFxPainter(
                          t: ((c - 0.40) / 0.60).clamp(0.0, 1.0),
                          v: visualFor(visible.last.cardId),
                          seed: visible.last.seq * 7 + 3,
                        ),
                      ),
                    ),
                  ),

                if (visible.isNotEmpty && c > 0.45 && c < 0.95)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: ImpactPainter(
                          t: ((c - 0.45) / 0.5).clamp(0.0, 1.0),
                          color: visualFor(visible.last.cardId).color,
                        ),
                      ),
                    ),
                  ),

                // quién la jugó
                if (visible.isNotEmpty)
                  Positioned(
                    top: 8,
                    child: Opacity(
                      opacity: c < 0.15
                          ? c / 0.15
                          : (c > 0.8 ? ((1 - c) / 0.2).clamp(0.0, 1.0) : 1.0),
                      child: Text(
                        '${visible.last.actor} juega '
                        '${kCards[visible.last.cardId]?.name ?? ''}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: visualFor(visible.last.cardId).color,
                        ),
                      ),
                    ),
                  ),

                if (widget.footer != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: widget.footer!,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _settled(PlayedEntry e, int depth) {
    // cuanto más abajo en la pila, más apagada y más chica
    final f = (1 - depth * 0.09).clamp(0.5, 1.0);
    return Transform.translate(
      offset: Offset(e.dx, e.dy - depth * 1.5),
      child: Transform.rotate(
        angle: e.rot,
        child: Transform.scale(
          scale: 0.86 * f,
          child: Opacity(
            opacity: (1 - depth * 0.13).clamp(0.15, 1.0),
            child: MiniCard(cardId: e.cardId, blocked: e.blocked),
          ),
        ),
      ),
    );
  }

  Widget _landing(PlayedEntry e, double c) {
    final drop = Curves.easeOutBack.transform((c / 0.5).clamp(0.0, 1.0));
    final scale = 1.85 - 0.99 * drop;
    final y = -78 + (e.dy + 78) * drop;
    final rot = e.rot + (1 - drop) * 0.7;
    final settle = c > 0.5 ? math.sin((c - 0.5) * 20) * (1 - c) * 2.2 : 0.0;

    return Transform.translate(
      offset: Offset(e.dx, y + settle),
      child: Transform.rotate(
        angle: rot,
        child: Transform.scale(
          scale: (0.86 * scale).clamp(0.4, 2.0),
          child: Opacity(
            opacity: (c * 6).clamp(0.0, 1.0),
            child: MiniCard(cardId: e.cardId, blocked: e.blocked),
          ),
        ),
      ),
    );
  }
}

/// El 6 y el 7 marcados al agua en la mesa: los números que no están en el mazo.
class _Watermark extends StatelessWidget {
  const _Watermark();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('6',
                style: SS.numStyle.copyWith(
                    fontSize: 96, color: Colors.white.withValues(alpha: 0.035))),
            const SizedBox(width: 18),
            Text('7',
                style: SS.numStyle.copyWith(
                    fontSize: 96, color: Colors.white.withValues(alpha: 0.035))),
          ],
        ),
      ),
    );
  }
}
