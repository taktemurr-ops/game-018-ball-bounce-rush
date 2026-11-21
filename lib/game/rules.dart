import 'package:studio_core/core/arcade.dart';
import 'package:studio_core/core/level_plan.dart';
import 'package:studio_core/core/missions.dart';
import 'package:studio_core/core/stats.dart';
import 'bounce_engine.dart';

class BounceRules extends ArcadeRules<BounceLevel> {
  @override
  String get gameId => 'game-018-ball-bounce-rush';

  @override
  List<String> get optionalMechanics => const ['double', 'ceilings', 'platforms', 'rings', 'fast'];

  @override
  List<GameStat> get gameStats => const [
        GameStat('jumps', 'Zıplama', 'Jumps', scale: 200),
        GameStat('rings', 'Halka', 'Rings', scale: 30),
        GameStat('distance_m', 'Mesafe (m)', 'Distance (m)', scale: 1000),
      ];

  @override
  List<MissionTemplate> get missionTemplates => const [
        MissionTemplate('jumps', 'jumps', [66, 133, 200]),
        MissionTemplate('rings', 'rings', [10, 20, 30]),
      ];

  @override
  BounceLevel generate(LevelSpec spec) => generateBounceLevel(spec);

  @override
  ArcadeMeta metaOf(BounceLevel l) => l.meta;

  @override
  ArcadeSim createSim(BounceLevel l) => BounceSim(l);

  @override
  ArcadeInput bot(ArcadeSim sim) => bounceBot(sim);
}

ArcadeRules createRules() => BounceRules();
