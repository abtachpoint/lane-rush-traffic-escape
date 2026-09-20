import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../models/car_model.dart';
import '../models/game_mode.dart';
import '../services/audio_service.dart';

class GameSnapshot {
  const GameSnapshot({
    required this.speed,
    required this.score,
    required this.distance,
    required this.earnedCoins,
    required this.nitro,
    required this.shieldSeconds,
    required this.magnetSeconds,
    required this.doubleCoinSeconds,
    required this.slowSeconds,
  });

  final int speed;
  final int score;
  final int distance;
  final int earnedCoins;
  final int nitro;
  final int shieldSeconds;
  final int magnetSeconds;
  final int doubleCoinSeconds;
  final int slowSeconds;
}

class RunResult {
  const RunResult({
    required this.score,
    required this.distance,
    required this.earnedCoins,
    required this.roadCoins,
    required this.dodges,
    required this.powerups,
  });

  final int score;
  final int distance;
  final int earnedCoins;
  final int roadCoins;
  final int dodges;
  final int powerups;
}

enum TrafficDirection { same, oncoming }
enum PickupType { shield, magnet, doubleCoin, slowMotion, nitro }

class LaneRushGame extends FlameGame {
  LaneRushGame({
    required this.mode,
    required this.playerModel,
    required this.onCrashed,
  });

  final TrafficMode mode;
  final CarModel playerModel;
  final VoidCallback onCrashed;

  final ValueNotifier<GameSnapshot> snapshot = ValueNotifier(
    const GameSnapshot(
      speed: 0,
      score: 0,
      distance: 0,
      earnedCoins: 0,
      nitro: 1,
      shieldSeconds: 0,
      magnetSeconds: 0,
      doubleCoinSeconds: 0,
      slowSeconds: 0,
    ),
  );

  final Random _random = Random();
  final Map<String, Sprite> _carSprites = {};
  final Map<PickupType, Sprite> _pickupSprites = {};
  late Sprite _coinSprite;
  late PlayerCarComponent player;

  final List<TrafficCarComponent> _traffic = [];
  final List<RoadCoinComponent> _coins = [];
  final List<PowerupComponent> _powerups = [];
  final List<String> _recentCarIds = [];

  int lane = 1;
  bool braking = false;
  bool nitroActive = false;
  bool gameOver = false;
  bool pausedByUser = false;
  bool usedRevive = false;
  bool _finalized = false;

  double currentSpeed = 0;
  double _trafficTimer = 0;
  double _coinTimer = 0;
  double _powerupTimer = 0;
  double _nitroTimer = 0;
  double _shieldTimer = 0;
  double _magnetTimer = 0;
  double _doubleCoinTimer = 0;
  double _slowTimer = 0;
  double _roadOffset = 0;
  double _snapshotTimer = 0;

  double distanceMeters = 0;
  int runCoins = 0;
  int roadCoinsCollected = 0;
  int dodges = 0;
  int powerupsUsed = 0;
  int nitroCount = 1;

  double get _normalTopSpeed => playerModel.topSpeed;
  double get _targetTopSpeed => _normalTopSpeed * (nitroActive ? 1.20 : 1.0);
  int get score => (distanceMeters * mode.multiplier + dodges * 40 * mode.multiplier).round();

  @override
  Color backgroundColor() => const Color(0xFF142036);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    for (final car in carCatalog) {
      _carSprites[car.id] = await loadSprite(car.asset.replaceFirst('assets/images/', ''));
    }
    _coinSprite = await loadSprite('ui/coin.png');
    _pickupSprites[PickupType.shield] = await loadSprite('ui/shield.png');
    _pickupSprites[PickupType.magnet] = await loadSprite('ui/magnet.png');
    _pickupSprites[PickupType.doubleCoin] = await loadSprite('ui/double_coin.png');
    _pickupSprites[PickupType.slowMotion] = await loadSprite('ui/slow_motion.png');
    _pickupSprites[PickupType.nitro] = await loadSprite('ui/nitro.png');

    currentSpeed = max(70.0, min(110.0, playerModel.topSpeed * 0.52));
    player = PlayerCarComponent(sprite: _carSprites[playerModel.id]!);
    add(player);
    _placePlayer();
    _powerupTimer = 7 + _random.nextDouble() * 5;
    _pushSnapshot();
  }

  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);
    if (isLoaded && player.isMounted) _placePlayer();
  }

  double laneX(int value) {
    final roadWidth = size.x * 0.78;
    final left = (size.x - roadWidth) / 2;
    final laneWidth = roadWidth / 3;
    return left + laneWidth * (value + 0.5);
  }

  void _placePlayer() {
    if (size.x <= 0 || size.y <= 0) return;
    player.position = Vector2(laneX(lane), size.y - 112);
    final scale = (size.x / 420).clamp(0.78, 1.20).toDouble();
    player.size = Vector2(56 * scale, 98 * scale);
  }

  void moveLeft() {
    if (gameOver || pausedByUser || lane <= 0) return;
    lane--;
    final x = laneX(lane);
    player.targetX = null;
    player.position.x = x;
    AudioService.instance.play('click.wav', volume: 0.12);
  }

  void moveRight() {
    if (gameOver || pausedByUser || lane >= 2) return;
    lane++;
    final x = laneX(lane);
    player.targetX = null;
    player.position.x = x;
    AudioService.instance.play('click.wav', volume: 0.12);
  }

  void setBrake(bool value) => braking = value;

  void useNitro() {
    if (gameOver || pausedByUser || nitroActive || nitroCount <= 0) return;
    nitroCount--;
    nitroActive = true;
    _nitroTimer = 5;
    powerupsUsed++;
    AudioService.instance.play('nitro.wav', volume: 0.30);
    _pushSnapshot();
  }

  void setPaused(bool value) {
    pausedByUser = value;
  }

  void revive() {
    if (!gameOver || usedRevive) return;
    usedRevive = true;
    gameOver = false;
    braking = false;
    lane = 1;
    player.targetX = laneX(lane);
    player.position.x = laneX(lane);
    currentSpeed = max(70.0, _normalTopSpeed * 0.58);
    _shieldTimer = 3.0;
    for (final car in List<TrafficCarComponent>.from(_traffic)) {
      if ((car.position.y - player.position.y).abs() < 260) {
        _removeTraffic(car);
      }
    }
    _pushSnapshot();
  }

  RunResult finalizeRun() {
    _finalized = true;
    return RunResult(
      score: score,
      distance: distanceMeters.round(),
      earnedCoins: runCoins,
      roadCoins: roadCoinsCollected,
      dodges: dodges,
      powerups: powerupsUsed,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isLoaded || pausedByUser || gameOver || _finalized) return;
    final safeDt = dt.clamp(0.0, 0.05).toDouble();

    _updateSpeed(safeDt);
    _updateTimers(safeDt);
    _updateRoadAndDistance(safeDt);
    _spawnTraffic(safeDt);
    _spawnCoins(safeDt);
    _spawnPowerups(safeDt);
    _updateTraffic(safeDt);
    _updateCoins(safeDt);
    _updatePowerups(safeDt);
    _checkCollisions();

    _snapshotTimer += safeDt;
    if (_snapshotTimer >= 0.10) {
      _snapshotTimer = 0;
      _pushSnapshot();
    }
  }

  void _updateSpeed(double dt) {
    final minSpeed = _normalTopSpeed * 0.45;
    if (braking) {
      currentSpeed = max(minSpeed, currentSpeed - 42 * dt);
    } else {
      currentSpeed = min(_targetTopSpeed, currentSpeed + playerModel.acceleration * dt);
    }
    if (nitroActive && currentSpeed < _targetTopSpeed) {
      currentSpeed = min(_targetTopSpeed, currentSpeed + 38 * dt);
    }
  }

  void _updateTimers(double dt) {
    if (_nitroTimer > 0) {
      _nitroTimer -= dt;
      if (_nitroTimer <= 0) nitroActive = false;
    }
    _shieldTimer = max(0.0, _shieldTimer - dt);
    _magnetTimer = max(0.0, _magnetTimer - dt);
    _doubleCoinTimer = max(0.0, _doubleCoinTimer - dt);
    _slowTimer = max(0.0, _slowTimer - dt);
  }

  void _updateRoadAndDistance(double dt) {
    final metersPerSecond = currentSpeed / 3.6;
    distanceMeters += metersPerSecond * dt;
    _roadOffset = (_roadOffset + currentSpeed * 0.95 * dt) % 150;
  }

  double get _difficulty {
    final secondsEquivalent = distanceMeters / max(1.0, currentSpeed / 3.6);
    if (secondsEquivalent < 30) return 0;
    if (secondsEquivalent < 60) return 0.30;
    if (secondsEquivalent < 120) return 0.65;
    return 1.0;
  }

  double get _baseTrafficInterval => switch (mode) {
        TrafficMode.sameDirection => 2.15,
        TrafficMode.oncoming => 2.55,
        TrafficMode.mixed => 1.85,
      };

  void _spawnTraffic(double dt) {
    _trafficTimer -= dt;
    if (_trafficTimer > 0) return;
    final interval = max(0.78, _baseTrafficInterval - _difficulty * 0.72);
    _trafficTimer = interval * (0.78 + _random.nextDouble() * 0.45);

    final availableLanes = [0, 1, 2]..shuffle(_random);
    int? chosenLane;
    for (final candidate in availableLanes) {
      final blocked = _traffic.any((t) => t.lane == candidate && t.position.y < 250);
      if (!blocked) {
        chosenLane = candidate;
        break;
      }
    }
    if (chosenLane == null) return;

    final model = _pickTrafficModel();
    final direction = switch (mode) {
      TrafficMode.sameDirection => TrafficDirection.same,
      TrafficMode.oncoming => TrafficDirection.oncoming,
      TrafficMode.mixed => _random.nextDouble() < 0.48 ? TrafficDirection.oncoming : TrafficDirection.same,
    };

    final component = TrafficCarComponent(
      sprite: _carSprites[model.id]!,
      model: model,
      lane: chosenLane,
      direction: direction,
    )
      ..position = Vector2(laneX(chosenLane), -110)
      ..size = Vector2(52, 92)
      ..angle = direction == TrafficDirection.oncoming ? pi : 0;
    _traffic.add(component);
    add(component);
  }

  CarModel _pickTrafficModel() {
    final candidates = carCatalog.where((c) => c.id != playerModel.id && !_recentCarIds.contains(c.id)).toList();
    final source = candidates.isEmpty ? carCatalog.where((c) => c.id != playerModel.id).toList() : candidates;
    final roll = _random.nextInt(100);
    final targetRarity = roll < 55
        ? CarRarity.common
        : roll < 80
            ? CarRarity.rare
            : roll < 95
                ? CarRarity.epic
                : CarRarity.legendary;
    final sameRarity = source.where((c) => c.rarity == targetRarity).toList();
    final pool = sameRarity.isEmpty ? source : sameRarity;
    final picked = pool[_random.nextInt(pool.length)];
    _recentCarIds.add(picked.id);
    if (_recentCarIds.length > 4) _recentCarIds.removeAt(0);
    return picked;
  }

  void _spawnCoins(double dt) {
    _coinTimer -= dt;
    if (_coinTimer > 0) return;
    _coinTimer = 1.15 + _random.nextDouble() * 0.85;
    final chosenLane = _random.nextInt(3);
    final count = 2 + _random.nextInt(4);
    for (var i = 0; i < count; i++) {
      final coin = RoadCoinComponent(sprite: _coinSprite, lane: chosenLane)
        ..position = Vector2(laneX(chosenLane), -55 - i * 70)
        ..size = Vector2(34, 34);
      _coins.add(coin);
      add(coin);
    }
  }

  void _spawnPowerups(double dt) {
    _powerupTimer -= dt;
    if (_powerupTimer > 0) return;
    _powerupTimer = 9 + _random.nextDouble() * 8;
    final type = PickupType.values[_random.nextInt(PickupType.values.length)];
    final chosenLane = _random.nextInt(3);
    final item = PowerupComponent(sprite: _pickupSprites[type]!, type: type, lane: chosenLane)
      ..position = Vector2(laneX(chosenLane), -70)
      ..size = Vector2(45, 45);
    _powerups.add(item);
    add(item);
  }

  double _trafficPixelsPerSecond(TrafficCarComponent car) {
    final slowFactor = _slowTimer > 0 ? 0.56 : 1.0;
    if (car.direction == TrafficDirection.oncoming) {
      return (245 + currentSpeed * 1.05) * slowFactor;
    }
    final relative = max(70.0, 100.0 + currentSpeed * 0.58 - car.model.topSpeed * 0.10);
    return relative * slowFactor;
  }

  void _updateTraffic(double dt) {
    for (final car in List<TrafficCarComponent>.from(_traffic)) {
      car.position.y += _trafficPixelsPerSecond(car) * dt;
      if (car.position.y > size.y + 130) {
        if (!car.countedDodge) {
          car.countedDodge = true;
          dodges++;
        }
        _removeTraffic(car);
      }
    }
  }

  void _updateCoins(double dt) {
    final speed = 180 + currentSpeed * 0.78;
    for (final coin in List<RoadCoinComponent>.from(_coins)) {
      coin.position.y += speed * dt;
      if (_magnetTimer > 0) {
        final delta = player.position - coin.position;
        if (delta.length < 210) {
          coin.position += delta.normalized() * 330 * dt;
        }
      }
      if (coin.position.y > size.y + 60) _removeCoin(coin);
    }
  }

  void _updatePowerups(double dt) {
    final speed = 180 + currentSpeed * 0.72;
    for (final p in List<PowerupComponent>.from(_powerups)) {
      p.position.y += speed * dt;
      p.angle += dt * 0.8;
      if (p.position.y > size.y + 70) _removePowerup(p);
    }
  }

  Rect _rectFor(PositionComponent c, {double inset = 0}) => Rect.fromCenter(
        center: Offset(c.position.x, c.position.y),
        width: max(1.0, c.size.x - inset * 2),
        height: max(1.0, c.size.y - inset * 2),
      );

  void _checkCollisions() {
    final playerRect = _rectFor(player, inset: 10);
    for (final car in List<TrafficCarComponent>.from(_traffic)) {
      if (playerRect.overlaps(_rectFor(car, inset: 9))) {
        if (_shieldTimer > 0) {
          _shieldTimer = 0;
          _removeTraffic(car);
          AudioService.instance.play('shield.wav', volume: 0.25);
          continue;
        }
        _crash();
        return;
      }
    }
    for (final coin in List<RoadCoinComponent>.from(_coins)) {
      if (playerRect.overlaps(_rectFor(coin, inset: 3))) {
        final value = _doubleCoinTimer > 0 ? 50 : 25;
        runCoins += value;
        roadCoinsCollected++;
        _removeCoin(coin);
        AudioService.instance.play('coin.wav', volume: 0.22);
      }
    }
    for (final p in List<PowerupComponent>.from(_powerups)) {
      if (playerRect.overlaps(_rectFor(p, inset: 2))) {
        _applyPowerup(p.type);
        _removePowerup(p);
      }
    }
  }

  void _applyPowerup(PickupType type) {
    powerupsUsed++;
    switch (type) {
      case PickupType.shield:
        _shieldTimer = 8;
        AudioService.instance.play('shield.wav', volume: 0.24);
        break;
      case PickupType.magnet:
        _magnetTimer = 10;
        break;
      case PickupType.doubleCoin:
        _doubleCoinTimer = 12;
        break;
      case PickupType.slowMotion:
        _slowTimer = 5;
        break;
      case PickupType.nitro:
        nitroCount = min(3, nitroCount + 1);
        AudioService.instance.play('reward.wav', volume: 0.22);
        break;
    }
    _pushSnapshot();
  }

  void _crash() {
    gameOver = true;
    braking = false;
    nitroActive = false;
    AudioService.instance.play('crash.wav', volume: 0.38);
    _pushSnapshot();
    onCrashed();
  }

  void _removeTraffic(TrafficCarComponent car) {
    _traffic.remove(car);
    car.removeFromParent();
  }

  void _removeCoin(RoadCoinComponent coin) {
    _coins.remove(coin);
    coin.removeFromParent();
  }

  void _removePowerup(PowerupComponent p) {
    _powerups.remove(p);
    p.removeFromParent();
  }

  void _pushSnapshot() {
    snapshot.value = GameSnapshot(
      speed: currentSpeed.round(),
      score: score,
      distance: distanceMeters.round(),
      earnedCoins: runCoins,
      nitro: nitroCount,
      shieldSeconds: _shieldTimer.ceil(),
      magnetSeconds: _magnetTimer.ceil(),
      doubleCoinSeconds: _doubleCoinTimer.ceil(),
      slowSeconds: _slowTimer.ceil(),
    );
  }

  @override
  void render(Canvas canvas) {
    _renderRoad(canvas);
    super.render(canvas);
  }

  void _renderRoad(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    if (w <= 0 || h <= 0) return;
    final roadWidth = w * 0.78;
    final left = (w - roadWidth) / 2;
    final right = left + roadWidth;

    final environment = (distanceMeters ~/ 1200) % 4;
    final sideColor = switch (environment) {
      0 => const Color(0xFF1B4B3B), // day greenery
      1 => const Color(0xFF5A382C), // evening warm roadside
      2 => const Color(0xFF101A31), // night
      _ => const Color(0xFF303845), // city
    };
    final roadColor = switch (environment) {
      0 => const Color(0xFF2A303A),
      1 => const Color(0xFF302D31),
      2 => const Color(0xFF202632),
      _ => const Color(0xFF2C3138),
    };
    final glowColor = switch (environment) {
      0 => const Color(0x553B82F6),
      1 => const Color(0x55F59E0B),
      2 => const Color(0x557C3AED),
      _ => const Color(0x5560A5FA),
    };

    final grass = Paint()..color = sideColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), grass);

    final glow = Paint()
      ..color = glowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawRect(Rect.fromLTWH(left - 7, 0, 14, h), glow);
    canvas.drawRect(Rect.fromLTWH(right - 7, 0, 14, h), glow);

    final road = Paint()..color = roadColor;
    canvas.drawRect(Rect.fromLTWH(left, 0, roadWidth, h), road);

    final edge = Paint()..color = const Color(0xFFE7EDF5);
    canvas.drawRect(Rect.fromLTWH(left + 3, 0, 4, h), edge);
    canvas.drawRect(Rect.fromLTWH(right - 7, 0, 4, h), edge);

    final lanePaint = Paint()..color = const Color(0xDDE8EDF4);
    final laneWidth = roadWidth / 3;
    for (var divider = 1; divider <= 2; divider++) {
      final x = left + laneWidth * divider;
      for (double y = -150 + _roadOffset; y < h + 150; y += 150) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x - 2.5, y, 5, 76), const Radius.circular(3)),
          lanePaint,
        );
      }
    }

    final sidePaint = Paint()..color = const Color(0xFF4F7C69);
    for (double y = -100 + (_roadOffset * .7); y < h + 100; y += 115) {
      canvas.drawCircle(Offset(left * .45, y), 9, sidePaint);
      canvas.drawCircle(Offset(right + (w - right) * .55, y + 45), 8, sidePaint);
    }
  }

  @override
  void onRemove() {
    snapshot.dispose();
    super.onRemove();
  }
}

class PlayerCarComponent extends SpriteComponent {
  PlayerCarComponent({required super.sprite}) : super(anchor: Anchor.center, size: Vector2(56, 98));
  double? targetX;

  @override
  void update(double dt) {
    super.update(dt);
    final target = targetX;
    if (target != null) {
      final dx = target - position.x;
      position.x += dx * min(1.0, dt * 12);
      if (dx.abs() < 0.5) {
        position.x = target;
        targetX = null;
      }
    }
  }
}

class TrafficCarComponent extends SpriteComponent {
  TrafficCarComponent({
    required super.sprite,
    required this.model,
    required this.lane,
    required this.direction,
  }) : super(anchor: Anchor.center);

  final CarModel model;
  final int lane;
  final TrafficDirection direction;
  bool countedDodge = false;
}

class RoadCoinComponent extends SpriteComponent {
  RoadCoinComponent({required super.sprite, required this.lane}) : super(anchor: Anchor.center);
  final int lane;
}

class PowerupComponent extends SpriteComponent {
  PowerupComponent({required super.sprite, required this.type, required this.lane}) : super(anchor: Anchor.center);
  final PickupType type;
  final int lane;
}
