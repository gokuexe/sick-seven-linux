# Sick Seven

Juego de cartas por turnos para 4 jugadores. Cada uno tiene una carta roja y
una azul con números del 0 al 5 y del 8 al 13. Gana el primero que consiga
tener 6 en una y 7 en la otra. El 6 y el 7 no existen en el mazo: hay que
construirlos con cartas de acción, pagando maná.

Esta versión corre contra 3 bots, sin conexión.

## Correrlo en Linux

Necesitás Flutter 3.27 o posterior (el código usa `Color.withValues`).

### Dependencias del sistema (Ubuntu/Debian)

```bash
sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev libblkid-dev liblzma-dev
```

### Compilar y ejecutar

```bash
flutter config --enable-linux-desktop
flutter pub get
flutter run -d linux
```

El repo ya incluye la carpeta `linux/`. Si la borraste o clonaste solo el
código Dart, regenerala con:

```bash
flutter create . --platforms=linux --project-name sick_seven
```

La ventana arranca en 520×900 (proporción de celular). El diseño escala solo
dentro de la app gracias a `_ResponsiveStage` en `main.dart`.

### Build de release

```bash
flutter build linux --release
./build/linux/x64/release/bundle/sick_seven
```

El ejecutable y sus librerías quedan en `build/linux/x64/release/bundle/`.
Podés empaquetar esa carpeta entera para distribuir.

## Otras plataformas

```bash
flutter create . --platforms=android,ios   # móvil
flutter create . --platforms=windows         # Windows
flutter pub get
flutter run
```

Para generar instalables:

```bash
flutter build apk --release          # APK Android
flutter build appbundle --release    # Play Store
flutter build windows --release      # Windows
```

## Cómo se juega

- Al empezar tu turno recuperás **3 maná** y robás una carta de acción.
- Jugás las cartas que quieras mientras te alcance el maná.
- **El maná que no gastás queda reservado** y sirve para interrumpir en el turno
  de los demás. Se pierde cuando arranca tu próximo turno.
- Si una carta pasa de 13 o baja de 0, **se quema**: se descarta y robás un
  número nuevo al azar. Todos ven que te quemaste.
- El botón de cantar solo se activa cuando tenés 6 y 7 de verdad. No se puede
  cantar en falso.
- Cuando alguien canta, se abre una ventana de 8 segundos para jugar
  **Desmentir** y anularlo.

Tus dos cartas son privadas. Las de los rivales aparecen tapadas hasta que las
mires con **Ojear**. El maná de cada uno, en cambio, es público: es la pista
principal de quién puede interrumpirte.

## Estructura

```
lib/
  main.dart              pantalla de título y arranque
  model.dart             jugadores, objetivos y catálogo del mazo (73 cartas)
  engine.dart            turnos, maná, quemado, reacciones, canto y bots
  sfx.dart               reproducción de efectos y háptica
  theme.dart             paleta y tipografía
  ui/
    game_screen.dart     pantalla de partida, conecta motor con sonido y FX
    number_card.dart     la carta grande, con quemado y brillo de victoria
    pieces.dart          rivales, maná, registro y mano
    overlays.dart        elecciones, ventana de reacción, final y confeti
linux/                   runner GTK para escritorio Linux
assets/audio/            11 efectos sintetizados (WAV, 388 KB)
```

`model.dart` y `engine.dart` no importan Flutter. Eso es a propósito: cuando
agregues el multijugador online, el mismo motor puede correr en el servidor
como árbitro, sin tocar la UI.

## Agregar una carta

En `model.dart`, sumá una entrada a `kCards`:

```dart
'miCarta': ActionCard(
  id: 'miCarta',
  name: 'Mi carta',
  desc: 'Lo que hace, en una línea.',
  cost: 2,
  family: CardFamily.interaccion,
  needs: const [Need.own, Need.foeCard],
  effect: (c) {
    c.bump(c.self, c.q.own!, 1);
    c.bump(c.players[c.q.foe!], c.q.foeColor!, -1);
  },
),
```

Y su cantidad en `kDeckList`. La UI la muestra sola, el color del borde sale de
`family`, y los bots la consideran sin cambios: si toca solo cartas propias la
simulan, y si apunta a un rival la juegan a ciegas como haría un jugador que no
ve las cartas ajenas.

## Lo que falta

- **Multijugador online.** El motor ya está aislado para esto.
- **Rastreo y Niebla**, las cartas que dependen de un historial más detallado
  que el registro actual.
- **Redirigir**, que necesita reasignar el objetivo de una carta en vuelo.
- Los bots eligen objetivo al azar cuando atacan. Es fiel a las reglas, pero
  podrían deducir mejor a partir del registro público.
