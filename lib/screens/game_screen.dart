import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/lane_rush_game.dart';
import '../models/car_model.dart';
import '../models/game_mode.dart';
import '../services/ad_service.dart';
import '../services/game_store.dart';
import '../widgets/game_widgets.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.mode});

  final TrafficMode mode;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late LaneRushGame game;
  bool crashed = false;
  bool saved = false;

  @override
  void initState() {
    super.initState();
    game = LaneRushGame(
      mode: widget.mode,
      playerModel: carById(GameStore.instance.selectedCarId),
      onCrashed: () {
        if (mounted) setState(() => crashed = true);
      },
    );
  }

  Future<void> _finalize() async {
    if (saved) return;
    saved = true;
    final r = game.finalizeRun();
    await GameStore.instance.addCoins(r.earnedCoins);
    await GameStore.instance.recordRun(
      score: r.score,
      distance: r.distance,
      roadCoins: r.roadCoins,
      dodges: r.dodges,
      powerups: r.powerups,
    );
    await AdService.instance.onRunCompleted();
  }

  Future<void> _home() async {
    await _finalize();
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  Future<void> _replay() async {
    await _finalize();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => GameScreen(mode: widget.mode)),
      );
    }
  }

  Future<void> _revive() async {
    if (game.usedRevive) return;
    final ok = await AdService.instance.showRewarded();
    if (ok) {
      game.revive();
      if (mounted) setState(() => crashed = false);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rewarded ad is not ready yet')),
      );
    }
  }

  Future<void> _pause() async {
    if (crashed) return;
    game.setPaused(true);
    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: const Text('PAUSED'),
        content: const Text('Take a break or continue the run.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, 'home'), child: const Text('HOME')),
          TextButton(onPressed: () => Navigator.pop(c, 'restart'), child: const Text('RESTART')),
          FilledButton(onPressed: () => Navigator.pop(c, 'resume'), child: const Text('RESUME')),
        ],
      ),
    );
    if (!mounted) return;
    if (action == 'home') {
      await _home();
      return;
    }
    if (action == 'restart') {
      await _replay();
      return;
    }
    game.setPaused(false);
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (!didPop) await _pause();
        },
        child: Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragEnd: (d) {
                    final v = d.primaryVelocity ?? 0;
                    if (v < -80) {
                      game.moveRight();
                    } else if (v > 80) {
                      game.moveLeft();
                    }
                  },
                  onTapDown: (d) {
                    final w = MediaQuery.sizeOf(context).width;
                    if (d.localPosition.dx < w / 2) {
                      game.moveLeft();
                    } else {
                      game.moveRight();
                    }
                  },
                  child: GameWidget(game: game),
                ),
              ),
              SafeArea(
                child: ValueListenableBuilder<GameSnapshot>(
                  valueListenable: game.snapshot,
                  builder: (_, s, __) => Stack(
                    children: [
                      Positioned(
                        left: 12,
                        top: 8,
                        child: IconButton.filledTonal(
                          onPressed: _pause,
                          icon: const Icon(Icons.pause_rounded),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        left: 75,
                        right: 75,
                        child: Column(
                          children: [
                            Text(
                              '${s.score}',
                              style: const TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w900,
                                shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                              ),
                            ),
                            Text(
                              '${s.distance} m • ${widget.mode.multiplier}×',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 12,
                        top: 11,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            children: [
                              Image.asset('assets/images/ui/coin.png', width: 20),
                              const SizedBox(width: 4),
                              Text('${s.earnedCoins}', style: const TextStyle(fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ),
                      ),
                      if (s.shieldSeconds + s.magnetSeconds + s.doubleCoinSeconds + s.slowSeconds > 0)
                        Positioned(
                          top: 67,
                          left: 14,
                          right: 14,
                          child: Wrap(
                            spacing: 7,
                            children: [
                              if (s.shieldSeconds > 0) _buff(Icons.shield, '${s.shieldSeconds}s'),
                              if (s.magnetSeconds > 0) _buff(Icons.u_turn_left, '${s.magnetSeconds}s'),
                              if (s.doubleCoinSeconds > 0) _buff(Icons.looks_two, '${s.doubleCoinSeconds}s'),
                              if (s.slowSeconds > 0) _buff(Icons.timer, '${s.slowSeconds}s'),
                            ],
                          ),
                        ),

                      // Nitro + speedometer moved to the left-side gameplay area.
                      Positioned(
                        left: 18,
                        bottom: 405,
                        child: _speedometer(s),
                      ),
                      Positioned(
                        left: 18,
                        bottom: 315,
                        child: _nitroButton(s.nitro),
                      ),

                      // Bottom controls: instant lane buttons with Brake in the middle.
                      Positioned(
                        left: 16,
                        bottom: 28,
                        child: _laneButton(
                          label: 'LEFT',
                          icon: Icons.arrow_back_rounded,
                          onPressed: game.moveLeft,
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 28,
                        child: Center(
                          child: _holdButton(
                            label: 'BRAKE',
                            icon: Icons.speed_rounded,
                            color: const Color(0xFFEF4444),
                            onDown: () => game.setBrake(true),
                            onUp: () => game.setBrake(false),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 16,
                        bottom: 28,
                        child: _laneButton(
                          label: 'RIGHT',
                          icon: Icons.arrow_forward_rounded,
                          onPressed: game.moveRight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (crashed)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: .72),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: NeonCard(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.car_crash_rounded, size: 58, color: Color(0xFFFB7185)),
                              const SizedBox(height: 6),
                              const Text('CRASH!', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 6),
                              ValueListenableBuilder<GameSnapshot>(
                                valueListenable: game.snapshot,
                                builder: (_, s, __) => Text(
                                  'Score ${s.score}  •  ${s.distance} m\nRun coins: ${s.earnedCoins}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ),
                              const SizedBox(height: 18),
                              if (!game.usedRevive)
                                GradientButton(
                                  label: 'REVIVE • WATCH AD',
                                  icon: Icons.ondemand_video_rounded,
                                  onPressed: _revive,
                                ),
                              if (!game.usedRevive) const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: _home,
                                    icon: const Icon(Icons.home_rounded),
                                    label: const Text('HOME'),
                                  ),
                                  const SizedBox(width: 10),
                                  FilledButton.icon(
                                    onPressed: _replay,
                                    icon: const Icon(Icons.replay_rounded),
                                    label: const Text('REPLAY'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );

  Widget _speedometer(GameSnapshot s) => SizedBox(
        width: 88,
        height: 88,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 82,
              height: 82,
              child: CircularProgressIndicator(
                value: (s.speed / 342).clamp(0.0, 1.0).toDouble(),
                strokeWidth: 6,
                backgroundColor: Colors.black38,
                color: game.nitroActive ? const Color(0xFFFBBF24) : const Color(0xFF60A5FA),
              ),
            ),
            Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                color: Color(0xAA111827),
                shape: BoxShape.circle,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${s.speed}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  const Text('km/h', style: TextStyle(fontSize: 9, color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buff(IconData i, String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(i, size: 15, color: const Color(0xFF93C5FD)),
            const SizedBox(width: 3),
            Text(t, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      );

  Widget _laneButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) =>
      Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => onPressed(),
        child: Container(
          width: 94,
          height: 66,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [BoxShadow(color: Color(0x552563EB), blurRadius: 15)],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 27),
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      );

  Widget _holdButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onDown,
    required VoidCallback onUp,
  }) =>
      GestureDetector(
        onTapDown: (_) => onDown(),
        onTapUp: (_) => onUp(),
        onTapCancel: onUp,
        child: Container(
          width: 86,
          height: 66,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .88),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: color.withValues(alpha: .32), blurRadius: 15)],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white),
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      );

  Widget _nitroButton(int count) => GestureDetector(
        onTap: game.useNitro,
        child: Container(
          width: 88,
          height: 65,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF2563EB)]),
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [BoxShadow(color: Color(0x557C3AED), blurRadius: 16)],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bolt_rounded, color: Color(0xFFFBBF24)),
              Text('NITRO ×$count', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      );
}
