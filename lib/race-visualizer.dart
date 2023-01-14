import 'dart:ui';

import 'package:fisrv/PlaybackModel.dart';
import 'package:fisrv/cmp/race-manager-cmp.dart';

import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/gestures.dart';
import 'package:flame/keyboard.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'cmp/course-cmp.dart';

class RaceVisualizer extends BaseGame
    with PanDetector, KeyboardEvents, ScrollDetector {
  bool ready = false;

  CourseCmp course;
  RaceManagerCmp raceManager;

  PlaybackModel pbm;
  PlaybackState newPlaybackState = PlaybackState.PAUSE;
  PlaybackState _playbackState = PlaybackState.PAUSE;

  RaceVisualizer() {
    course = CourseCmp('cc-2215');
  }


  Future<void> onLoad() async {
    init();
  }

  Future<void> init() async {


    await course.fisLoader.loader;

    raceManager = RaceManagerCmp(course);
    raceManager.init();
    final flags =
        raceManager.skiers.map((it) => 'flags/${it.nation}.png').toList();

    try {
      await Flame.images.loadAll(['flags/mask.png', ...flags]);
    } catch (e) {}

    course.fisLoader.race.finalize();
    ready = true;

    return;
  }

  void render(Canvas canvas) {
    if (size == null) return;
    if (!ready) return;

    Rect bgRect = Rect.fromLTWH(0, 0, size.x, size.y);
    Paint bgPaint = Paint();
    bgPaint.color = Color(0xff576574);
    canvas.drawRect(bgRect, bgPaint);

    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.scale(size.x* zoom / 110, -size.y*zoom / 150);
    canvas.translate(0, 20);
    canvas.translate(xOffset,yOffset);
    course.render(canvas);
    raceManager.skiers.forEach((it) => it.render(canvas));

    canvas.restore();

    raceManager.render(canvas);
  }

  bool isShift = false;

  onKeyEvent(e) {
    isShift = e.isShiftPressed && !(e is RawKeyUpEvent);
  }

  double xOffset = 0;
  double yOffset = 0;

  void onPanUpdate(DragUpdateDetails details) {
    xOffset -= details.delta.dx * -.1;
    yOffset += details.delta.dy * -.1;
  }



  double zoom = 1;
  void onScroll(PointerScrollEvent event) {
    zoom -= .1 * event.scrollDelta.dy.sign;
  }

  @override
  void update(double t) {
    if (!ready) return;

    if (newPlaybackState != _playbackState) {
      _playbackState = newPlaybackState;

      switch (_playbackState) {
        case PlaybackState.PLAY:
          raceManager.timeFactor = 1;
          break;
        case PlaybackState.REWIND:
          raceManager.timeFactor = -1;
          break;
        case PlaybackState.FASTFORWARD:
          raceManager.timeFactor = 20;
          break;
        case PlaybackState.PAUSE:
          raceManager.timeFactor = 0;
          break;
        case PlaybackState.RESTART:
          raceManager.restart();
          pbm.state = PlaybackState.PAUSE;
          break;
      }
    }
    course.update(t);
    raceManager.update(t);
    raceManager.skiers.forEach((it) => it.update(t));
  }

  @override
  void onResize(Vector2 _size) {

    super.onResize(_size);
    course.onGameResize(_size);
    newPlaybackState = PlaybackState.PAUSE;
  }
}
