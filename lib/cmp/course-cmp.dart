import 'dart:ui';

import 'package:fisrv/cmp/split-cmp.dart';
import 'package:fisrv/fis/load-fis.dart';
import 'package:fisrv/fis/race-metrics.dart';
import 'package:fisrv/fis/race.dart';
import 'package:fisrv/units.dart';
import 'package:flame/components.dart';

import 'package:flutter/material.dart';

class CourseCmp extends Component {
  final String homologationId;

  LoadFis fisLoader;
  EventRace fisRace;

  double fromMeters = 0;
  double toMeters = 10000;

  RaceMetrics raceMetrics;

  List<Offset> points;

  List<SplitCmp> _splits;

  CourseCmp(this.homologationId) {
    init();
  }

  init() async {
    fisLoader = LoadFis.fromHtml(homologationId);

    await fisLoader.loader;
    fisRace = fisLoader.race;

    raceMetrics = RaceMetrics(fisRace);
    points = raceMetrics
        .getProfile(fromMeters, toMeters)
        .map((it) => Offset(it.x / raceMetrics.distance * 100, it.y / 100))
        .toList();

    _splits = fisRace.segments
        .map<SplitCmp>((it) => SplitCmp(raceMetrics, it))
        .toList();
    _splits.add(SplitCmp(raceMetrics, null));
  }

  @override
  void render(Canvas c) {
    renderLap(c);
    renderProfile(c);
  }

  void renderProfile(Canvas c) {
    c.save();
    c.translate(-50, -60);

    Paint paint2 = Paint();
    paint2.color = Colors.green;
    paint2.strokeWidth = .2;
    paint2.strokeCap = StrokeCap.round;

    c.drawPoints(PointMode.lines, points, paint2);

    c.restore();

    _splits.forEach((it) => it.render(c));
  }

  void renderLap(Canvas c) {
    Paint paint = Paint();
    paint.color = Colors.green;
    paint.strokeWidth = .21;
    paint.strokeCap = StrokeCap.butt;
    paint.style = PaintingStyle.stroke;
    double lapLength = 5000;
    double startAngle = 0;
    int i = 0;
    while (startAngle < 360 * DEGREES) {
      final it = _splits[i];
      double sweepAngle = it.segment.distanceMeters / lapLength * 360 * DEGREES;
      final st = raceMetrics.segmentTopo[it.segment.id];
      c.drawArc(
          Rect.fromCenter(center: Offset(0, 0), width: 100, height: 100),
          startAngle,
          sweepAngle,
          false,
          paint
            ..color = st.risePerMeter > 0
                ? Colors.red.withRed((st.risePerMeter * 2550).truncate())
                : Colors.green);
      startAngle += sweepAngle;
      i++;
    }

    _splits.forEach((it) => it.renderLap(c));
  }

  @override
  void update(double t) {
    //fromMeters += t* 100;
  }

  void updateFromTo(double primaryDelta) {
    fromMeters += primaryDelta;
    toMeters += primaryDelta;
  }

  void addSplitTime(Racer skier, Split split, splitTime) {
    if (split == null) return; // todo
    final sp = _splits.singleWhere((it) => split.segment == it.segment,
        orElse: () => null);
    sp?.add(skier, splitTime);
  }
}
