import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/mission.dart';

class GameStore extends ChangeNotifier {
  GameStore._();
  static final GameStore instance = GameStore._();

  late SharedPreferences _prefs;

  int coins = 500;
  int bestScore = 0;
  String selectedCarId = 'red_hatch';
  Set<String> unlockedCars = {'red_hatch'};
  bool removeAds = false;
  bool soundOn = true;
  bool musicOn = true;
  bool vibrationOn = true;

  int totalDistance = 0;
  int totalRoadCoins = 0;
  int totalDodges = 0;
  int totalRuns = 0;
  int totalPowerups = 0;
  Set<String> claimedMissions = {};
  Set<String> processedPurchases = {};

  String lastDailyClaim = '';
  int dailyStreak = 0;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    coins = _prefs.getInt('coins') ?? 500;
    bestScore = _prefs.getInt('best_score') ?? 0;
    selectedCarId = _prefs.getString('selected_car') ?? 'red_hatch';
    unlockedCars = (_prefs.getStringList('unlocked_cars') ?? ['red_hatch']).toSet();
    unlockedCars.add('red_hatch');
    removeAds = _prefs.getBool('remove_ads') ?? false;
    soundOn = _prefs.getBool('sound_on') ?? true;
    musicOn = _prefs.getBool('music_on') ?? true;
    vibrationOn = _prefs.getBool('vibration_on') ?? true;
    totalDistance = _prefs.getInt('total_distance') ?? 0;
    totalRoadCoins = _prefs.getInt('total_road_coins') ?? 0;
    totalDodges = _prefs.getInt('total_dodges') ?? 0;
    totalRuns = _prefs.getInt('total_runs') ?? 0;
    totalPowerups = _prefs.getInt('total_powerups') ?? 0;
    claimedMissions = (_prefs.getStringList('claimed_missions') ?? []).toSet();
    processedPurchases = (_prefs.getStringList('processed_purchases') ?? []).toSet();
    lastDailyClaim = _prefs.getString('last_daily_claim') ?? '';
    dailyStreak = _prefs.getInt('daily_streak') ?? 0;
  }

  Future<void> addCoins(int amount) async {
    coins += amount;
    await _prefs.setInt('coins', coins);
    notifyListeners();
  }

  Future<bool> spendCoins(int amount) async {
    if (coins < amount) return false;
    coins -= amount;
    await _prefs.setInt('coins', coins);
    notifyListeners();
    return true;
  }

  Future<bool> unlockCar(String id, int price) async {
    if (unlockedCars.contains(id)) return true;
    if (!await spendCoins(price)) return false;
    unlockedCars.add(id);
    await _prefs.setStringList('unlocked_cars', unlockedCars.toList());
    notifyListeners();
    return true;
  }

  Future<void> selectCar(String id) async {
    if (!unlockedCars.contains(id)) return;
    selectedCarId = id;
    await _prefs.setString('selected_car', id);
    notifyListeners();
  }

  Future<void> setRemoveAds(bool value) async {
    removeAds = value;
    await _prefs.setBool('remove_ads', value);
    notifyListeners();
  }

  Future<void> setSound(bool value) async {
    soundOn = value;
    await _prefs.setBool('sound_on', value);
    notifyListeners();
  }

  Future<void> setMusic(bool value) async {
    musicOn = value;
    await _prefs.setBool('music_on', value);
    notifyListeners();
  }

  Future<void> setVibration(bool value) async {
    vibrationOn = value;
    await _prefs.setBool('vibration_on', value);
    notifyListeners();
  }

  Future<void> recordRun({
    required int score,
    required int distance,
    required int roadCoins,
    required int dodges,
    required int powerups,
  }) async {
    if (score > bestScore) {
      bestScore = score;
      await _prefs.setInt('best_score', bestScore);
    }
    totalDistance += distance;
    totalRoadCoins += roadCoins;
    totalDodges += dodges;
    totalRuns += 1;
    totalPowerups += powerups;
    await Future.wait([
      _prefs.setInt('total_distance', totalDistance),
      _prefs.setInt('total_road_coins', totalRoadCoins),
      _prefs.setInt('total_dodges', totalDodges),
      _prefs.setInt('total_runs', totalRuns),
      _prefs.setInt('total_powerups', totalPowerups),
    ]);
    notifyListeners();
  }

  int missionProgress(Mission mission) => switch (mission.metric) {
        MissionMetric.distance => totalDistance,
        MissionMetric.coins => totalRoadCoins,
        MissionMetric.dodges => totalDodges,
        MissionMetric.runs => totalRuns,
        MissionMetric.powerups => totalPowerups,
      };

  Future<bool> claimMission(Mission mission) async {
    if (claimedMissions.contains(mission.id)) return false;
    if (missionProgress(mission) < mission.target) return false;
    claimedMissions.add(mission.id);
    coins += mission.reward;
    await Future.wait([
      _prefs.setStringList('claimed_missions', claimedMissions.toList()),
      _prefs.setInt('coins', coins),
    ]);
    notifyListeners();
    return true;
  }

  bool get canClaimDaily {
    final today = _dayKey(DateTime.now());
    return lastDailyClaim != today;
  }

  int get nextDailyReward {
    const rewards = [200, 300, 450, 600, 800, 1000, 2000];
    final next = canClaimDaily ? dailyStreak % 7 : (dailyStreak - 1).clamp(0, 6).toInt();
    return rewards[next];
  }

  Future<int> claimDaily() async {
    if (!canClaimDaily) return 0;
    final now = DateTime.now();
    final today = _dayKey(now);
    final yesterday = _dayKey(now.subtract(const Duration(days: 1)));
    if (lastDailyClaim == yesterday) {
      dailyStreak = (dailyStreak % 7) + 1;
    } else {
      dailyStreak = 1;
    }
    const rewards = [200, 300, 450, 600, 800, 1000, 2000];
    final reward = rewards[dailyStreak - 1];
    coins += reward;
    lastDailyClaim = today;
    await Future.wait([
      _prefs.setString('last_daily_claim', lastDailyClaim),
      _prefs.setInt('daily_streak', dailyStreak),
      _prefs.setInt('coins', coins),
    ]);
    notifyListeners();
    return reward;
  }

  bool isPurchaseProcessed(String key) => processedPurchases.contains(key);

  Future<void> markPurchaseProcessed(String key) async {
    processedPurchases.add(key);
    if (processedPurchases.length > 120) {
      processedPurchases = processedPurchases.skip(processedPurchases.length - 120).toSet();
    }
    await _prefs.setStringList('processed_purchases', processedPurchases.toList());
  }

  String _dayKey(DateTime dt) => '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
