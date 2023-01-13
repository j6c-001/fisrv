import 'dart:math';
import 'dart:ui';

import 'package:fisrv/cmp/race-manager-cmp.dart';
import 'package:fisrv/fis/race.dart';
import 'package:flame/components.dart';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../units.dart';

enum SkierState { WARMUP, QUEUING, STARTLINE, RACING, FINISHED }

class SkierCmp extends PositionComponent {
  final RaceManagerCmp _raceManager;
  final double startTime;
  double finishTime = 1111111111111110;
  final Racer _racer;

  String get nation => _racer.details.nation;

  SkierState state;
  double _distance = 0;

  double get dist => _distance;

  Offset lapXY;

  Split _currentSplit;

  SkierCmp(this._raceManager, this._racer, this.startTime) {
    x = Random().nextDouble() * -25;
    y = Random().nextDouble() * -25;
  }

  Offset warmupTarget =
      Offset(Random().nextDouble() * -12, Random().nextDouble() * -12) +
          Offset(12, 12);

  Offset cooldownTarget = Offset.zero;

  @override
  void update(double dt) {
    state = getState();

    final nextSplitAt = _currentSplit?.segment?.endMeters ?? 0;
    if (_distance > nextSplitAt) {
      _raceManager.addSplit(
          this._racer, this.startTime, _distance, _currentSplit);
      _currentSplit = _racer.getSegmentAtDistance(_distance);
    }

    switch (state) {
      case SkierState.WARMUP:
        final dist = (Offset(x, y) - warmupTarget).distance;
        if (dist < 1) {
          warmupTarget =
              Offset(Random().nextDouble() * -12, Random().nextDouble() * -12) +
                  Offset(12, 12);
        }

        final dir = (warmupTarget - Offset(x, y)) /
            (Offset(x, y) - warmupTarget).distance;
        final delta = dir * (3 * dt * _raceManager.timeFactor / 5);

        x += delta.dx;
        y += delta.dy;

        break;

      case SkierState.FINISHED:
        final dist = (Offset(x, y) - cooldownTarget).distance;
        if (dist < 1 || cooldownTarget.dx == 0) {
          final end =
              _raceManager.metrics.getPointAtDistance(_raceManager.distance);
          cooldownTarget =
              Offset(Random().nextDouble() * -12, Random().nextDouble() * -12) +
                  Offset(12, 12);
        }

        final dir = (cooldownTarget - Offset(x, y)) /
            (Offset(x, y) - cooldownTarget).distance;
        final delta = dir * (dt);

        x += delta.dx;
        y += delta.dy;

        break;

      case SkierState.QUEUING:
        final p = _raceManager.metrics.getPointAtDistance(0) +
            Offset(-(startTime - _raceManager.time), 0) * (1 / 10.0) +
            Offset(50, 0);
        final dist = (Offset(x, y) - p).distance;
        final dir = (p - Offset(x, y)) / dist;
        final delta = dir * (2 * dt * _raceManager.timeFactor / 5);

        if (dist > 1) {
          x += delta.dx;
          y += delta.dy;
        }
        break;
      case SkierState.STARTLINE:
        // TODO: Handle this case.
        final p = Offset(50, 0);
        final dist = (Offset(x, y) - p).distance;
        final dir = (p - Offset(x, y)) / dist;
        final delta = dir * (2 * dt * _raceManager.timeFactor);

        if (dist > 1) {
          x += delta.dx;
          y += delta.dy;
        } else {
          x = 50;
          y = 0;
        }

        break;
      case SkierState.RACING:
        final speed = _racer.getSpeedAtDistance(_distance);
        _distance += speed * dt * _raceManager.timeFactor;
        lapXY = Offset(50 * cos(_distance / 5000 * 360 * DEGREES),
            50 * sin(_distance / 5000 * 360 * DEGREES));
        final p = _raceManager.metrics.getPointAtDistance(_distance);
        x = p.dx / _raceManager.metrics.distance * 100 - 50;
        y = p.dy / 100 - 60;
        break;
      case SkierState.FINISHED:
        finishTime = _raceManager.time - startTime;
        // TODO: Handle this case.
        break;
    }
  }

  Color get color {
    switch (_racer.details.nation) {
      case 'USA':
        return Colors.redAccent;
      case 'NOR':
        return Colors.greenAccent;
      case 'RUS':
        return Colors.teal;
      case 'SWE':
        return Colors.white;
    }
    return Colors.grey;
  }

  static const Rect skierRect = Rect.fromLTWH(0, 0, 2, 1.5);
  final Paint paint = Paint();


  @override
  void render(Canvas c) {
    c.save();
    c.translate(x, y);
    if (_racer.details.flag != null) {
      //c.clipPath(_clipPath);
      final i = _racer.details.flag;
      c.drawImageRect(
          i,
          Rect.fromLTWH(0, 0, i.width.toDouble(), i.height.toDouble()),
          Rect.fromLTWH(0, 0, 1, 1),
          paint);
    } else {
      c.drawCircle(Offset.zero, .33, paint..color = Colors.grey);
    }
    c.restore();

    if (state == SkierState.RACING) {
      c.save();
      c.translate(lapXY.dx, lapXY.dy);
      c.scale(1,-1);
      if (_racer.details.flag != null && _racer.details.mask != null) {
        //c.clipPath(_clipPath);
        final i = _racer.details.flag;
        ImageShader shader = ImageShader(i, TileMode.repeated,
            TileMode.repeated, Matrix4.identity().storage);
        final p = Paint()
          ..shader = shader
          ..blendMode = BlendMode.srcIn;
        //  c.saveLayer(skierRect, p);
        c.drawImageRect(
            i,
            Rect.fromLTWH(0, 0, i.width.toDouble(), i.height.toDouble()),
            skierRect,
            paint);
        renderName(c, 0,0);
        //c.restore();
      } else {
        c.drawCircle(Offset.zero, .75, paint..color = Colors.grey);
      }
      c.restore();
    }
  }
  final TextConfig _configNames = TextConfig(fontSize: 1, color: Colors.black54);
  renderName(Canvas c, double xx, double yy) {
    final _tp = _configNames.toTextPainter(_racer.details.name);
    _tp.paint(c, Offset(xx, yy));
  }

  SkierState getState() {
    final timeUntilStart = startTime - _raceManager.time;
    if (timeUntilStart > 5 * MINUTES) {
      return SkierState.WARMUP;
    }
    if (timeUntilStart > 30 * SECONDS) {
      return SkierState.QUEUING;
    }

    if (timeUntilStart > 0) {
      return SkierState.STARTLINE;
    }

    if (_raceManager.distance <= _distance) {
      return SkierState.FINISHED;
    }

    return SkierState.RACING;
  }
}
