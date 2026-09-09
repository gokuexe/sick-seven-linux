import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'sfx.dart';
import 'theme.dart';
import 'ui/game_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const SickSevenApp());
}

class SickSevenApp extends StatelessWidget {
  const SickSevenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sick Seven',
      debugShowCheckedModeBanner: false,
      theme: SS.theme(),
      // En escritorio la ventana es mucho más ancha que un teléfono. Sin este
      // límite las cartas se estirarían a lo ancho de todo el monitor.
      builder: (context, child) => ColoredBox(
        color: SS.table,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: child,
          ),
        ),
      ),
      home: const TitleScreen(),
    );
  }
}

class TitleScreen extends StatefulWidget {
  const TitleScreen({super.key});

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    Sfx.i.init();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: SS.tableBg(),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // El 6 y el 7 flotando: son justo los números que el mazo no
                  // tiene, así que abrir con ellos dice de qué va el juego.
                  AnimatedBuilder(
                    animation: _c,
                    builder: (context, _) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _bigNumber(6, true, _c.value),
                          const SizedBox(width: 14),
                          _bigNumber(7, false, 1 - _c.value),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 34),
                  const Text('SICK SEVEN', style: SS.title),
                  const SizedBox(height: 10),
                  const Text(
                    'Ni el 6 ni el 7 están en el mazo.\nHay que construirlos.',
                    textAlign: TextAlign.center,
                    style: SS.sub,
                  ),
                  const SizedBox(height: 36),
                  GestureDetector(
                    onTap: () {
                      Sfx.i.tap();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const GameScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 46, vertical: 15),
                      decoration: BoxDecoration(
                        color: SS.mana,
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: [
                          BoxShadow(
                            color: SS.mana.withValues(alpha: 0.35),
                            blurRadius: 24,
                          )
                        ],
                      ),
                      child: const Text(
                        'Jugar contra 3 bots',
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
          ),
        ),
      ),
    );
  }

  Widget _bigNumber(int n, bool red, double t) {
    return Transform.translate(
      offset: Offset(0, -6 + 12 * t),
      child: Container(
        width: 86,
        height: 116,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [SS.upOf(red), SS.of(red)],
          ),
          boxShadow: [
            BoxShadow(
              color: SS.of(red).withValues(alpha: 0.35),
              blurRadius: 26,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Text('$n', style: SS.numStyle.copyWith(fontSize: 54)),
      ),
    );
  }
}
