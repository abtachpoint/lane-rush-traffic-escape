import 'package:flutter/material.dart';

import '../models/mission.dart';
import '../services/game_store.dart';
import '../widgets/game_widgets.dart';

class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> {
  final store = GameStore.instance;

  @override
  void initState() {
    super.initState();
    store.addListener(_refresh);
  }

  @override
  void dispose() {
    store.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('MISSIONS'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CoinBadge(coins: store.coins),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [for (final mission in missions) _missionCard(mission)],
        ),
      );

  Widget _missionCard(Mission mission) {
    final progressValue = store.missionProgress(mission);
    final claimed = store.claimedMissions.contains(mission.id);
    final done = progressValue >= mission.target;
    final progress = (progressValue / mission.target).clamp(0.0, 1.0).toDouble();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NeonCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    mission.title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                Text(
                  '+${mission.reward}',
                  style: const TextStyle(
                    color: Color(0xFFFBBF24),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 4),
                Image.asset('assets/images/ui/coin.png', width: 20),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(10),
              backgroundColor: Colors.white10,
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Text(
                  '${progressValue.clamp(0, mission.target)} / ${mission.target}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const Spacer(),
                if (claimed)
                  const Text(
                    'CLAIMED',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else if (done)
                  GradientButton(
                    label: 'CLAIM',
                    compact: true,
                    onPressed: () => store.claimMission(mission),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
