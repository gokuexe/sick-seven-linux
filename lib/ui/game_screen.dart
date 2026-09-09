import 'package:flutter/material.dart';

import '../engine.dart';
import '../model.dart';
import '../sfx.dart';
import '../theme.dart';
import 'number_card.dart';
import 'overlays.dart';
import 'pieces.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  final GameEngine engine = GameEngine();

  late final AnimationController _fly = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  );
  ActionCard? _flyCard;
  String _flyActor = '';

  @override
  void initState() {
    super.initState();
    engine.onFx = _handleFx;
    engine.addListener(_onEngine);
    _fly.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _flyCard = null);
      }
    });
    Sfx.i.init();
  }

  void _onEngine() {
    if (mounted) setState(() {});
  }

  void _handleFx(Fx fx) {
    switch (fx.kind) {
      case FxKind.play:
        final card = kCards[fx.cardId];
        if (card != null) {
          setState(() {
            _flyCard = card;
            _flyActor = fx.actorName ?? '';
          });
          _fly.forward(from: 0);
        }
        Sfx.i.play('play');
        Sfx.i.tap();
        break;
      case FxKind.draw:
        Sfx.i.play('draw', volume: 0.5);
        break;
      case FxKind.mana:
        Sfx.i.play('mana', volume: 0.6);
        break;
      case FxKind.burn:
        Sfx.i.play('burn');
        if (fx.playerId == 0) Sfx.i.heavy();
        break;
      case FxKind.block:
        Sfx.i.play('block');
        Sfx.i.thump();
        break;
      case FxKind.sing:
        Sfx.i.play('sing');
        Sfx.i.thump();
        break;
      case FxKind.deny:
        Sfx.i.play('deny');
        Sfx.i.heavy();
        break;
      case FxKind.win:
        Sfx.i.play('win');
        Sfx.i.heavy();
        break;
      case FxKind.lose:
        Sfx.i.play('lose');
        break;
      case FxKind.turn:
        if (fx.playerId == 0) {
          Sfx.i.play('turn', volume: 0.5);
          Sfx.i.play('mana', volume: 0.35);
        }
        break;
    }
  }

  @override
  void dispose() {
    engine.removeListener(_onEngine);
    engine.onFx = null;
    engine.dispose();
    _fly.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final me = engine.me;
    final myTurn = engine.myTurn;

    return Scaffold(
      body: Container(
        decoration: SS.tableBg(),
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _header(),
                    const SizedBox(height: 10),
                    _rivals(),
                    const SizedBox(height: 10),
                    Expanded(child: LogView(entries: engine.logs)),
                    const SizedBox(height: 10),
                    _myCards(me),
                    const SizedBox(height: 10),
                    _status(me),
                    const SizedBox(height: 10),
                    _hand(me, myTurn),
                    const SizedBox(height: 8),
                    _buttons(me, myTurn),
                  ],
                ),
              ),
              if (_flyCard != null)
                FlyingCard(actor: _flyActor, card: _flyCard!, anim: _fly),
              if (engine.choice != null)
                ChoiceOverlay(
                  key: ValueKey(engine.choice),
                  request: engine.choice!,
                  onPick: engine.answer,
                ),
              if (engine.winner != null)
                EndOverlay(
                  winner: engine.winner!,
                  youWon: engine.winner == 'Vos',
                  onAgain: () {
                    Sfx.i.tap();
                    engine.newGame();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('SICK SEVEN', style: SS.title),
              const SizedBox(height: 2),
              Text(
                engine.winner != null
                    ? 'Partida terminada'
                    : 'Turno de ${engine.current.name}',
                style: SS.sub,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => setState(() => Sfx.i.muted = !Sfx.i.muted),
          icon: Icon(
            Sfx.i.muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            color: SS.mute,
            size: 21,
          ),
          tooltip: Sfx.i.muted ? 'Activar sonido' : 'Silenciar',
        ),
      ],
    );
  }

  Widget _rivals() {
    final foes = engine.foesOf(0);
    return Row(
      children: [
        for (var i = 0; i < foes.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: RivalPanel(
              player: foes[i],
              active: engine.turn == foes[i].id,
              seesRed: engine.seesCard(foes[i].id, CardColor.red),
              seesBlue: engine.seesCard(foes[i].id, CardColor.blue),
            ),
          ),
        ],
      ],
    );
  }

  Widget _myCards(Player me) {
    return Row(
      children: [
        Expanded(
          child: NumberCard(
            isRed: true,
            value: me.red,
            win: me.isWin,
            burnToken: engine.burnTokens['0-${CardColor.red.index}'] ?? 0,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: NumberCard(
            isRed: false,
            value: me.blue,
            win: me.isWin,
            burnToken: engine.burnTokens['0-${CardColor.blue.index}'] ?? 0,
          ),
        ),
      ],
    );
  }

  Widget _status(Player me) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Text('Maná ', style: SS.sub),
            ManaPips(value: me.mana, max: 7),
            const SizedBox(width: 8),
            Text(
              me.free > 0 ? '${me.mana} · ${me.free} gratis' : '${me.mana}',
              style: SS.sub,
            ),
          ],
        ),
        Text(
          me.isWin ? 'lo tenés' : 'te faltan ${me.distance}',
          style: SS.sub.copyWith(color: me.isWin ? SS.win : SS.mute),
        ),
      ],
    );
  }

  Widget _hand(Player me, bool myTurn) {
    return SizedBox(
      height: 118,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: me.hand.length,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (context, i) {
          final card = kCards[me.hand[i]]!;
          final cost = me.free > 0 ? 0 : card.cost;
          final enabled = myTurn &&
              !me.frozen &&
              !card.isReaction &&
              cost <= me.mana;
          return HandCard(
            card: card,
            enabled: enabled,
            onTap: () => engine.humanPlay(i),
          );
        },
      ),
    );
  }

  Widget _buttons(Player me, bool myTurn) {
    final canSing = myTurn && me.isWin;
    return Row(
      children: [
        Expanded(
          child: _Btn(
            label: 'Cantar Sick Seven',
            enabled: canSing,
            filled: true,
            onTap: () {
              Sfx.i.tap();
              engine.sing(0);
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Btn(
            label: 'Terminar turno',
            enabled: myTurn,
            onTap: () {
              Sfx.i.tap();
              engine.endTurn();
            },
          ),
        ),
      ],
    );
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool filled;
  final VoidCallback onTap;

  const _Btn({
    required this.label,
    required this.enabled,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final active = enabled && filled;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? SS.win : SS.surface,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: active ? SS.win : SS.line),
          boxShadow: active
              ? [BoxShadow(color: SS.win.withValues(alpha: 0.4), blurRadius: 16)]
              : null,
        ),
        child: Opacity(
          opacity: enabled ? 1 : 0.35,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: active ? const Color(0xFF0D2419) : SS.ink,
            ),
          ),
        ),
      ),
    );
  }
}
