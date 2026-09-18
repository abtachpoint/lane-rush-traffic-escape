enum TrafficMode { sameDirection, oncoming, mixed }

extension TrafficModeInfo on TrafficMode {
  String get title => switch (this) {
        TrafficMode.sameDirection => 'Same Direction',
        TrafficMode.oncoming => 'Oncoming Traffic',
        TrafficMode.mixed => 'Mixed Traffic',
      };

  String get subtitle => switch (this) {
        TrafficMode.sameDirection => 'Overtake traffic moving with you',
        TrafficMode.oncoming => 'Dodge cars coming straight at you',
        TrafficMode.mixed => 'Same-direction + oncoming traffic',
      };

  String get difficulty => switch (this) {
        TrafficMode.sameDirection => 'EASY',
        TrafficMode.oncoming => 'MEDIUM',
        TrafficMode.mixed => 'HARD',
      };

  double get multiplier => switch (this) {
        TrafficMode.sameDirection => 1.0,
        TrafficMode.oncoming => 1.5,
        TrafficMode.mixed => 2.0,
      };
}
