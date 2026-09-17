enum MissionMetric { distance, coins, dodges, runs, powerups }

class Mission {
  const Mission({
    required this.id,
    required this.title,
    required this.metric,
    required this.target,
    required this.reward,
  });

  final String id;
  final String title;
  final MissionMetric metric;
  final int target;
  final int reward;
}

const missions = <Mission>[
  Mission(id: 'distance_1000', title: 'Drive 1,000 m', metric: MissionMetric.distance, target: 1000, reward: 500),
  Mission(id: 'distance_3000', title: 'Drive 3,000 m', metric: MissionMetric.distance, target: 3000, reward: 1200),
  Mission(id: 'coins_50', title: 'Collect 50 road coins', metric: MissionMetric.coins, target: 50, reward: 400),
  Mission(id: 'dodges_20', title: 'Dodge 20 traffic cars', metric: MissionMetric.dodges, target: 20, reward: 600),
  Mission(id: 'runs_5', title: 'Complete 5 runs', metric: MissionMetric.runs, target: 5, reward: 750),
  Mission(id: 'powerups_3', title: 'Use 3 power-ups', metric: MissionMetric.powerups, target: 3, reward: 500),
];
