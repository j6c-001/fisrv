import 'dart:math';
import 'dart:ui';
import 'dart:ui' as ui show Image;

import 'package:fisrv/fis/race-metrics.dart';
import 'package:fisrv/fis/race.dart';
import 'package:fisrv/units.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

String toString(double d) {
  var hh = d / 3600;
  var HH = hh.truncate();
  var mm = (hh - HH) * 60;
  var MM = mm.truncate();
  var ss = (mm - MM) * 60;
  var SS = ss.truncate();
  var FS = ((ss - SS) * 10).round();

  if (FS == 10) SS++;

  return (HH > 0 ? '$HH:' : '') + (MM > 0 ? '$MM:' : '') + '$SS.$FS';
}

final TextConfig _configNames = TextConfig(fontSize: 1, color: Colors.black54);
final TextConfig _configTimes =
    TextConfig(fontSize: 1, color: Colors.black54, textAlign: TextAlign.right);

class RenderedSplit {
  final int bib;
  final double time;
  final ui.Image _flag;
  TextPainter _rank;
  final TextPainter _bib;
  final TextPainter _name;
  final TextPainter _time;
  TextPainter _diff;
  final double height;
  final Rect _flagRect;
  final Paint _p = Paint();

  RenderedSplit(this.bib, this.time, this._flag, this._bib, this._name,
      this._rank, this._time, this._diff)
      : height = _name.height,
        _flagRect = _flag != null
            ? Rect.fromLTWH(
                0, 0, _flag.width.toDouble(), _flag.height.toDouble())
            : Rect.zero;

  void render(Canvas c, double y) {
    _rank.paint(c, Offset(0, y));
    if (_flag != null) {
      c.drawImageRect(
          _flag, _flagRect, Rect.fromLTWH(1, y + 1, 5, height - 2), _p);
    }
  /*  _bib.paint(c, Offset(2, y));
    _name.paint(c, Offset(3, y));
    _time.paint(c, Offset(15 - _time.width, y));
    if (_diff != null) {
      _diff.paint(c, Offset(20 - _diff.width, y));
    }*/
  }

  factory RenderedSplit.create(
      {String name,
      int bib,
      int rank,
      double time,
      double diff,
      ui.Image flag}) {
    final _name = _configNames.toTextPainter(name);
    final _bib = _configNames.toTextPainter(bib.toString());
    final _rank = _configNames.toTextPainter(rank.toString());

    final _time = _configTimes.toTextPainter(toString(time));
    final _diff =
        rank > 1 ? _configTimes.toTextPainter('+' + toString(diff)) : null;

    return RenderedSplit(bib, time, flag, _bib, _name, _rank, _time, _diff);
  }

  update({int rank, double fistPlaceTime}) {
    _rank = _configNames.toTextPainter(rank.toString());
    if (fistPlaceTime != null) {
      _diff = rank > 1
          ? _configTimes.toTextPainter('+' + toString(time - fistPlaceTime))
          : null;
    }
  }
}

class SkierSplit {
  final Racer skier;
  final double time;
  final String fmtTime;

  SkierSplit(this.skier, this.time) : fmtTime = toString(time);
}

class SplitCmp extends Component {
  final RaceSegment segment;
  final Offset xy;
  final Offset lapXY;
  final Color _color;
  final String _text;
  final TextConfig _config = TextConfig(fontSize: 9, color: Colors.blueAccent);

  final List<SkierSplit> _times = [];

  static const List<Offset> FLAG = [
    Offset(0, 0),
    Offset(0, 10 * METERS),
    Offset(0, 10 * METERS),
    Offset(3 * METERS, 9 * METERS),
    Offset(3 * METERS, 9 * METERS),
    Offset(0, 8 * METERS)
  ];

  SplitCmp(RaceMetrics rm, this.segment)
      : xy = rm.getPointAtDistance(segment?.endMeters ?? 0) * METERS,
        lapXY = Offset(
            50 * cos((segment?.endMeters ?? 0) / 5000 * 360 * DEGREES),
            50 * sin((segment?.endMeters ?? 0) / 5000 * 360 * DEGREES)),
        _color = getColor(segment),
        _text = segment == null
            ? 'Start'
            : ((segment?.endMeters ?? 0) / 1000).toStringAsPrecision(2) + 'km';

  void renderLap(Canvas c) {
    c.save();
    c.translate(lapXY.dx, lapXY.dy);

    c.scale(4, 4);
    c.drawPoints(
        PointMode.lines,
        FLAG,
        Paint()
          ..color = _color
          ..strokeWidth = .1);

    c.scale(.05, -.05);
    final _tp = _config.toTextPainter(_text);
    _tp.paint(
        c,
        Offset.zero +
            Offset(0, 10.0 * ((segment?.endMeters ?? 0) / 5000).truncate()));

    c.restore();
  }

  @override
  void render(Canvas c) {
    c.save();
    c.translate(xy.dx, xy.dy);

    c.scale(4, 4);

    c.drawPoints(
        PointMode.lines,
        FLAG,
        Paint()
          ..color = _color
          ..strokeWidth = .1);

    c.restore();

    c.save();

    c.scale(1, -1);
    c.translate(xy.dx, -xy.dy);
    final _tp = _config.toTextPainter(_text);
    _tp.paint(c, Offset.zero);

    c.translate(0, xy.dy + 60);

    double yy = 0;

    _rendererSplits.forEach((it) {
      it.render(c, yy);
      yy += it.height;
    });

    c.restore();

    return;
  }

  List<RenderedSplit> _rendererSplits = [];

  updateTarget(Racer skier, double splitTime) {
    final rd = _rendererSplits;
    final double fastestSplit =
        min(rd.isEmpty ? splitTime : rd.first.time, splitTime);

    final newSplit = (int rank) => RenderedSplit.create(
        name: skier.details.shortName,
        bib: skier.bib,
        time: splitTime,
        diff: splitTime - fastestSplit,
        flag: skier.details.flag,
        rank: rank);

    int i = rd.indexWhere((it) => it.time > splitTime);

    if (i == -1) {
      rd.add(newSplit(rd.length + 1));
    } else {
      rd.insert(i, newSplit(i + 1));
      final updateDiffs = i == 0;
      while (i < rd.length) {
        rd[i].update(
            rank: i + 1, fistPlaceTime: updateDiffs ? fastestSplit : null);
        i++;
      }
    }
  }

  @override
  void update(double t) {
    // TODO: implement update
  }

  static Color getColor(RaceSegment segment) {
    if (segment == null) {
      return Colors.green;
    } else if (segment.isLast) return Colors.red;

    return Colors.amber;
  }

  void add(Racer skier, double splitTime) {
    _times.add(SkierSplit(skier, splitTime));
    _times.sort((a, b) => a.time.compareTo(b.time));
    updateTarget(skier, splitTime);
  }
}

const Map<String, String> flagMap = {
  'CAN': 'c',
  'FIN': '²',
  'SWE': 'w',
  'AUS': 'A',
  'NOR': 'W',
  'SUI': 'q',
  'USA': 'u',
  'POL': 'P',
  'RUS': 'r',
  'SLO': '¦',
  'JPN': 'j',
  'GER': 'g',
  'ITA': 'i',
  'FRA': 'f',
  'CZE': ')'
};
