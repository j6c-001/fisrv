import 'dart:ui';

import 'package:fisrv/cmp/skier-cmp.dart';
import 'package:fisrv/fis/race-metrics.dart';
import 'package:fisrv/fis/race.dart';
import 'package:flame/components.dart';

import 'package:flame/sprite.dart';
import 'package:flutter/cupertino.dart';

import '../units.dart';
import 'course-cmp.dart';

class RaceManagerCmp extends Component {
  final CourseCmp _course;
  final EventRace _race;
  final RaceMetrics metrics;

  double time = 0;

  double timeFactor = 1;

  double get distance => metrics.distance;

  RaceManagerCmp(this._course)
      : _race = _course.fisRace,
        metrics = _course.raceMetrics;

  Map<String, Sprite> flags;

  init() {
    createStartList();
    Start();
  }

  Start() {
    time = 0;
  }

  List<SkierCmp> skiers = [];

  createStartList() {
    skiers.clear();
    final racers = _race.getRacers();
    racers.sort((r0, r1) => r0.bib.compareTo(r1.bib));
    double startTime = 0;
    for (var r in racers) {
      final sc = SkierCmp(this, r, startTime);
      skiers.add(sc);

      startTime +=  30 * SECONDS;
    }
  }

  @override
  void render(Canvas c) {}

  @override
  void update(double t) {
    time += t * timeFactor;
  }

  void addSplit(Racer skier, double startTime, double distance, Split split) {
    final double delta = distance - (split?.segment?.endMeters ?? 0.0),
        dt = delta / (split?.avgSpeed ?? 0),
        splitTime = time - dt;
    _course.addSplitTime(skier, split, splitTime - startTime);
  }

  void restart() {
    time = 0;
    createStartList();
  }
}
