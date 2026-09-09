import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../engine.dart';
import '../model.dart';
import '../theme.dart';
import 'card_art.dart';

/// Panel de un rival. Sus dos cartas están tapadas hasta que las mires con
/// Ojear; el maná en cambio siempre es público, y es la mejor pista de si
/// puede interrumpirte.
class RivalPanel extends StatelessWidget {
  final Player player;
  final bool active;
  final bool seesRed;
  final bool seesBlue;

  const RivalPanel({
    super.key,
    required this.player,
    required this.active,
    required this.seesRed,
    required this.seesBlue,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: active ? SS.surfaceUp : SS.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? SS.mana : SS.line,
          width: active ? 1.6 : 1,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: SS.mana.withValues(alpha: 0.22),
                  blurRadius: 14,
                )
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            player.name,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: active ? SS.ink : SS.mute,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _chip(true, seesRed ? player.red : null),
              const SizedBox(width: 4),
              _chip(false, seesBlue ? player.blue : null),
            ],
          ),
          const SizedBox(height: 6),
          Text('${player.hand.length} cartas',
              style: const TextStyle(fontSize: 9.5, color: SS.mute)),
          const SizedBox(height: 4),
          ManaPips(value: player.mana, max: 5, size: 5),
        ],
      ),
    );
  }

  Widget _chip(bool red, int? value) {
    final known = value != null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      width: 27,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: known ? SS.of(red) : const Color(0xFF2B4859),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: known
              ? SS.upOf(red).withValues(alpha: 0.7)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Text(
        known ? '$value' : '?',
        style: SS.numStyle.copyWith(
          fontSize: 15,
          color: known ? Colors.white : const Color(0xFF5F8299),
        ),
      ),
    );
  }
}

/// Puntitos de maná. Se llenan con un pequeño rebote para que gastarlo se note.
class ManaPips extends StatelessWidget {
  final int value;
  final int max;
  final double size;

  const ManaPips({
    super.key,
    required this.value,
    this.max = 7,
    this.size = 11,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(max, (i) {
        final on = i < value;
        return Padding(
          padding: EdgeInsets.only(right: i == max - 1 ? 0 : size * 0.32),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: on ? 1.0 : 0.0),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutBack,
            builder: (context, t, _) => Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.lerp(const Color(0xFF3A5A6C), SS.mana, t),
                boxShadow: t > 0.5
                    ? [
                        BoxShadow(
                          color: SS.mana.withValues(alpha: 0.45 * t),
                          blurRadius: size * 0.8,
                        )
                      ]
                    : null,
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Registro público de la partida. Es la única fuente de información sobre los
/// rivales, así que conviene que se lea cómodo.
class LogView extends StatefulWidget {
  final List<LogEntry> entries;
  const LogView({super.key, required this.entries});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  final _ctrl = ScrollController();

  @override
  void didUpdateWidget(covariant LogView old) {
    super.didUpdateWidget(old);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_ctrl.hasClients) {
        _ctrl.animateTo(
          _ctrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListView.builder(
        controller: _ctrl,
        padding: EdgeInsets.zero,
        itemCount: widget.entries.length,
        itemBuilder: (context, i) {
          final e = widget.entries[i];
          final last = i == widget.entries.length - 1;
          return Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              e.text,
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: last || e.loud ? SS.ink : SS.mute,
                fontWeight: e.loud ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Una carta de acción en la mano. Usa el mismo ícono y color que su versión
/// en la pila, para que se reconozca de un vistazo qué va a caer si se juega.
/// Se mece sola con un movimiento leve y desincronizado entre cartas, así la
/// mano se siente viva sin llamar la atención.
class HandCard extends StatefulWidget {
  final ActionCard card;
  final bool enabled;
  final VoidCallback onTap;

  const HandCard({
    super.key,
    required this.card,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<HandCard> createState() => _HandCardState();
}

const double _handCardW = 138;
const double _handCardH = 216;

class _HandCardState extends State<HandCard> with TickerProviderStateMixin {
  late final AnimationController _idle;
  late final AnimationController _flip;
  bool _showBack = false;

  @override
  void initState() {
    super.initState();
    final seed = widget.card.id.hashCode;
    _idle = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2200 + seed % 700),
    )
      ..value = (seed % 1000) / 1000
      ..repeat(reverse: true);
    _flip = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void dispose() {
    _idle.dispose();
    _flip.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    setState(() => _showBack = !_showBack);
    _showBack ? _flip.forward() : _flip.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final v = visualFor(widget.card.id);
    return AnimatedBuilder(
      animation: _idle,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_idle.value);
        return Transform.translate(
          offset: Offset(0, -2 + t * 2.2),
          child: Transform.rotate(
            angle: (t - 0.5) * 0.022,
            child: AnimatedBuilder(
              animation: _flip,
              builder: (context, __) {
                final angle = Curves.easeInOut.transform(_flip.value) * math.pi;
                final backHalf = angle > math.pi / 2;
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0016)
                    ..rotateY(angle),
                  child: backHalf
                      ? Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()..rotateY(math.pi),
                          child: _back(v),
                        )
                      : _front(v),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _flipButton() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleFlip,
      child: Container(
        width: 20,
        height: 20,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.4),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: const Icon(Icons.cached_rounded, size: 13, color: Colors.white),
      ),
    );
  }

  Widget _costBadge(CardVisual v) {
    if (widget.card.isReaction) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: SS.react,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(color: SS.react.withValues(alpha: 0.5), blurRadius: 6),
          ],
        ),
        child: const Text(
          'REAC',
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            color: Colors.white,
          ),
        ),
      );
    }
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: SS.mana,
        boxShadow: [
          BoxShadow(color: SS.mana.withValues(alpha: 0.5), blurRadius: 6),
        ],
      ),
      child: Text(
        '${widget.card.cost}',
        style: SS.numStyle.copyWith(fontSize: 13, color: const Color(0xFF2B1E00)),
      ),
    );
  }

  /// Una esquinita en diagonal, como el filo tallado de una carta de
  /// colección: le da esa sensación de "ficha cargada" al panel de arte.
  Widget _corner(Color c) => Transform.rotate(
        angle: math.pi / 4,
        child: Container(width: 5, height: 5, color: c.withValues(alpha: 0.7)),
      );

  Widget _front(CardVisual v) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: widget.enabled ? 1 : 0.4,
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: Container(
          width: _handCardW,
          height: _handCardH,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(SS.surfaceUp, v.color, 0.16)!,
                Color.lerp(SS.surface, v.color, 0.04)!,
              ],
            ),
            border: Border.all(
              color: v.color.withValues(alpha: widget.enabled ? 0.6 : 0.22),
              width: 1.6,
            ),
            boxShadow: widget.enabled
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: v.color.withValues(alpha: 0.28),
                      blurRadius: 14,
                      spreadRadius: -3,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // cabecera: solo ícono + nombre, sin competir por ancho
                  // con las insignias (van superpuestas más abajo)
                  Container(
                    height: 27,
                    padding: const EdgeInsets.fromLTRB(9, 0, 30, 0),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: v.color.withValues(alpha: 0.22),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(14),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(v.icon, size: 14, color: v.color),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.card.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: SS.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // panel de arte: el mismo efecto de partículas que se ve
                  // al jugarla, de fondo, para que la ficha se sienta viva
                  Container(
                    margin: const EdgeInsets.fromLTRB(7, 7, 7, 6),
                    height: 60,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: RadialGradient(
                        colors: [
                          Color.lerp(SS.surfaceUp, v.color, 0.4)!,
                          Color.lerp(SS.surface, v.color, 0.08)!,
                        ],
                      ),
                      border:
                          Border.all(color: v.color.withValues(alpha: 0.5)),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: CardFxPainter(
                              t: 0.5,
                              v: v,
                              seed: widget.card.id.hashCode,
                            ),
                          ),
                        ),
                        Icon(v.icon, size: 28, color: v.color),
                        Positioned(top: 3, left: 3, child: _corner(v.color)),
                        Positioned(top: 3, right: 3, child: _corner(v.color)),
                        Positioned(
                            bottom: 3, left: 3, child: _corner(v.color)),
                        Positioned(
                            bottom: 3, right: 3, child: _corner(v.color)),
                      ],
                    ),
                  ),
                  // la frase social, cortita, con mucho más aire que antes
                  Padding(
                    padding: const EdgeInsets.fromLTRB(7, 0, 7, 6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: v.color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color: v.color.withValues(alpha: 0.55)),
                        ),
                        child: Text(
                          v.social,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // la descripción, sobre un panel oscuro propio: sin esto
                  // el texto se leía apagado sobre el degradé de la carta
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(7, 0, 7, 7),
                      padding: const EdgeInsets.all(8),
                      alignment: Alignment.topLeft,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.26),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        widget.card.desc,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: SS.ink,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(top: 19, right: 7, child: _costBadge(v)),
              Positioned(top: 4, right: 4, child: _flipButton()),
            ],
          ),
        ),
      ),
    );
  }

  /// El dorso: el ícono grande de la carta, como un sello. Tocarlo la vuelve
  /// a poner del lado jugable.
  Widget _back(CardVisual v) {
    return GestureDetector(
      onTap: _toggleFlip,
      child: Container(
        width: _handCardW,
        height: _handCardH,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(SS.surfaceUp, v.color, 0.32)!,
              Color.lerp(SS.surface, v.color, 0.10)!,
            ],
          ),
          border: Border.all(color: v.color.withValues(alpha: 0.6), width: 1.6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(v.icon, size: 58, color: v.color),
            const SizedBox(height: 14),
            Text(
              widget.card.name.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: SS.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              v.social,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: v.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
