import 'dart:math';

import 'package:fisrv/fis/race.dart';
import 'package:flutter/cupertino.dart';

class SegTopo {
  final double startHeight;
  final double startHorizontalDistance;
  final double risePerMeter;
  final RaceSegment seg;

  SegTopo(this.startHeight, this.startHorizontalDistance, this.seg,
      this.risePerMeter);

  double get deltaHeight => seg.distanceMeters * risePerMeter;

  double get endHeight => startHeight + deltaHeight;

  double get endHorizontalDistance =>
      startHorizontalDistance +
      sqrt(seg.distanceMeters * seg.distanceMeters - deltaHeight * deltaHeight);

  double getHeightAtDistanceInRace(double d) =>
      min(d - seg.startMeters, seg.distanceMeters) * risePerMeter + startHeight;

  double getHorizontalDistanceAtDistanceInRace(double d) {
    if (d > seg.endMeters) {
      return d;
    }
    final double l = d - seg.startMeters, h = l * risePerMeter;
    return startHorizontalDistance + sqrt(l * l - h * h);
  }
}

class Height {
  final double x;
  final double y;

  Height(this.x, this.y);
}

bool between(double s, double a, double b) => s >= a && s <= b;

class RaceMetrics {
  double distance;

  double courseAvgSpeed = 0;
  Map<int, double> segmentAvgSpeed = Map();
  Map<int, SegTopo> segmentTopo = Map();

  List<Height> getProfile(double startMeters, double endMeters) {
    List<SegTopo> topos = segmentTopo.values
        .where((it) =>
            between(it.seg.startMeters, startMeters, endMeters) ||
            between(startMeters, it.seg.startMeters, it.seg.endMeters) ||
            between(endMeters, it.seg.startMeters, it.seg.endMeters))
        .toList();
    final List<Height> profile = [];

    final fs = topos.removeAt(0);
    final ls = topos.isNotEmpty ? topos.removeLast() : null;
    endMeters = min(endMeters, ls.seg.endMeters);

    profile.add(Height(fs.getHorizontalDistanceAtDistanceInRace(startMeters),
        fs.getHeightAtDistanceInRace(startMeters)));
    profile.add(Height(fs.endHorizontalDistance, fs.endHeight));
    if (ls == null) {
      return profile;
    }
    for (var s in topos) {
      profile.add(Height(s.startHorizontalDistance, s.startHeight));
      profile.add(Height(s.endHorizontalDistance, s.endHeight));
    }

    profile.add(Height(ls.startHorizontalDistance, ls.startHeight));

    profile.add(Height(ls.getHorizontalDistanceAtDistanceInRace(endMeters),
        ls.getHeightAtDistanceInRace(endMeters)));

    return profile;
  }

  Offset getPointAtDistance(double d) {
    SegTopo t = segmentTopo.values.firstWhere(
        (it) => between(d, it.seg.startMeters, it.seg.endMeters),
        orElse: () => null);
    if (t == null) {
      final l = segmentTopo.values.last;
      if (d > l.seg.endMeters) {
        return Offset(l.getHorizontalDistanceAtDistanceInRace(l.seg.endMeters),
            l.getHeightAtDistanceInRace(l.seg.endMeters));
      } else {
        return Offset(d, 0);
      }
    }
    return Offset(t.getHorizontalDistanceAtDistanceInRace(d),
        t.getHeightAtDistanceInRace(d));
  }

  RaceMetrics(EventRace race) {
    final racers = race.getRacers();
    distance = race.segments.last.endMeters;

    Map<int, double> speedTally = Map();
    Map<int, int> tally = Map();

    for (var r in racers) {
      for (var s in r.split) {
        final id = s.segment.id;
        speedTally[id] = (speedTally[id] ?? 0) + s.avgSpeed;
        tally[id] = (tally[id] ?? 0) + 1;
      }
    }

    for (var it in tally.entries) {
      segmentAvgSpeed[it.key] = speedTally[it.key] / it.value;
      courseAvgSpeed += segmentAvgSpeed[it.key];
    }

    courseAvgSpeed /= tally.length;
    double h = 0;
    double x = 0;

    double maxDeviation = 0;
    for (var it in race.segments) {
      double dev = (courseAvgSpeed - segmentAvgSpeed[it.id]).abs();
      if (dev > maxDeviation) {
        maxDeviation = dev;
      }
    }

    for (var it in race.segments) {
      double risePerMeter =
          (courseAvgSpeed - segmentAvgSpeed[it.id]) / (maxDeviation + 2);
      SegTopo topo = SegTopo(h, x, it, risePerMeter);
      segmentTopo[it.id] = topo;
      h = topo.endHeight;
      x = topo.endHorizontalDistance;
    }
  }
}
