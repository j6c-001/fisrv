import 'dart:ui';

import 'package:flame/flame.dart';

class EventRace {
  EventRace({this.name, this.lapDistance = 0});

  final String name;
  final double lapDistance;

  Map<String, String> _info = Map();

  Map<int, Racer> _racer = Map();

  List<RaceSegment> _segment = [];

  Racer getRacer(int bib) {
    return _racer[bib];
  }


  finalize() {
    _racer.values.forEach((it)=>it.details.finalize()) ;
  }
  List<Racer> getRacers() => _racer.values.toList();

  addOrderedSegment(int id, double totalDistanceMeters) {
    double startMeters = _segment.length > 0 ? _segment.last?.endMeters : 0;
    double endMeters = totalDistanceMeters;
    _segment.add(
        RaceSegment(id: id, startMeters: startMeters, endMeters: endMeters));
  }

  segmentCount() => _segment.length;

  List<RaceSegment> get segments => _segment;

  addRacer(int bib, RacerDetails details) {
    _racer[bib] = Racer(bib, details);
  }

  addOrUpdateOrderedSplit(int bib, double elapsedTimeSeconds, int id) {
    final racer = _racer[bib];
    final segment = _segment.firstWhere((it) => it.id == id);
    racer.addOrderedSplit(elapsedTimeSeconds, segment);
  }

  List<RacerSnapshot> getState(double elapsedSeconds) {
    final temp = <RacerSnapshot>[];

    _racer.values.forEach((it) {
      temp.add(it.getSnapshot(elapsedSeconds));
    });

    temp.sort((a, b) => b.sortForRanking.compareTo(a.sortForRanking));
    final first = temp[0];

    int rank = 1;
    final state = temp.map((it) => RacerSnapshot.clone(it,
        metersBack: first.distance - it.distance, rank: rank++));

    return state.toList()..sort((a, b) => a.sort.compareTo(b.sort));
  }

  void removeRacersWithMissingSegments() {
    final expectedSegmentCount = segmentCount();
    _racer.removeWhere(
        (key, value) => value.splitCount() != expectedSegmentCount);
  }

  void addEventInfo(String name, String value) {
    _info[name] = value;
  }
}

class RacerSnapshot {
  final Racer racer;
  final double distance;
  final double metersBack;
  final int rank;
  final double sortForRanking;
  final int sort;
  final double finishSeconds;

  bool get finish => finishSeconds > 0;
  final bool error;

  RacerSnapshot(this.racer, this.distance, this.metersBack, this.rank,
      this.finishSeconds, this.error)
      : sortForRanking =
            finishSeconds > 0 ? (10000000 - finishSeconds / 1000) : distance,
        sort = racer.pinned ? -1000 + rank : rank;

  static RacerSnapshot forPartial(Racer racer, double distance) =>
      RacerSnapshot(racer, distance, 0, 0, 0, false);

  static RacerSnapshot forFinished(
          Racer racer, double distance, double finishSeconds) =>
      RacerSnapshot(racer, distance, 0, 0, finishSeconds, false);

  static RacerSnapshot forError(Racer racer) =>
      RacerSnapshot(racer, 0, 0, 0, 0, true);

  RacerSnapshot.clone(RacerSnapshot rs, {double metersBack, int rank})
      : this(rs.racer, rs.distance, metersBack ?? rs.metersBack,
            rank ?? rs.rank, rs.finishSeconds, rs.error);
}

class RaceSegment {
  final int id;
  final double startMeters;
  final double endMeters;
  final double distanceMeters;
  final bool isLast;

  RaceSegment({this.id, this.startMeters, this.endMeters})
      : distanceMeters = endMeters - startMeters,
        isLast = id == 99;
}

class Racer {
  final int bib;
  final RacerDetails details;
  final List<Split> _split = [];

  List<Split> get split => _split;

  int splitCount() => _split.length;

  bool pinned = false;
  bool starred = false;

  addOrderedSplit(double raceTimeSeconds, RaceSegment segment) {
    int idx = _split.indexWhere((it) => it.segment.id == segment.id);
    double prevTime =
            idx == -1 && _split.isNotEmpty ? _split.last.raceTimeSeconds : 0,
        timeSeconds = raceTimeSeconds - prevTime;

    final split = Split(raceTimeSeconds, timeSeconds, segment);
    if (idx == -1) {
      _split.add(split);
    } else {
      _split[idx] = split;
    }
  }

  Racer(this.bib, this.details);

  double getSpeedAtDistance(double dist) {
    Split sp = _split.firstWhere(
        (it) => it.segment.startMeters <= dist && it.segment.endMeters >= dist,
        orElse: () =>
            Split(1, 1, RaceSegment(id: -1, startMeters: 0, endMeters: 0)));
    return sp.avgSpeed;
  }

  RacerSnapshot getSnapshot(double elapsedTimeSeconds) {
    final index =
        _split.indexWhere((it) => it.timeSeconds > elapsedTimeSeconds);
    if (index == -1) {
      if (elapsedTimeSeconds > 0 && _split.length > 0) {
        final finishSplit = _split.last;
        return RacerSnapshot.forFinished(
            this, finishSplit.segment.endMeters, finishSplit.timeSeconds);
      }
      return RacerSnapshot.forError(this);
    }
    final split = _split[index];
    final prevSplit = index > 0 ? _split[index - 1] : null;
    final segment = split.segment;
    final double segmentTime =
        elapsedTimeSeconds - (prevSplit?.timeSeconds ?? 0);
    final double segmentSpeed = segment.distanceMeters /
        (split.timeSeconds - (prevSplit?.timeSeconds ?? 0));
    final double segmentDistance = segmentTime * segmentSpeed;

    return RacerSnapshot.forPartial(
        this, segment.startMeters + segmentDistance);
  }

  Split getSegmentAtDistance(double dist) {
    Split sp = _split.firstWhere(
        (it) => it.segment.startMeters <= dist && it.segment.endMeters >= dist,
        orElse: () =>
            Split(1, 1, RaceSegment(id: -1, startMeters: 0, endMeters: 0)));
    return sp;
  }
}

class Split {
  final double raceTimeSeconds;
  final double timeSeconds;
  final RaceSegment segment;

  double get avgSpeed => segment.distanceMeters / timeSeconds;

  Split(this.raceTimeSeconds, this.timeSeconds, this.segment);
}

class RacerDetails {
  Image mask;
  Image flag;

  final String name;
  String get shortName => lastName + ' ' + firstName.substring(0, 1);
  final String firstName;

  final String lastName;
  final String nation;

  finalize() {
    mask = Flame.images.fromCache('flags/mask.png');
    try {
      flag = Flame.images.fromCache('flags/$nation.png');
    }
    catch(e) {

    }


  }

  RacerDetails(this.name, this.nation) :
        firstName =
            name.split(' ').where((it) => it != it.toUpperCase()).join(' '),
        lastName =
            name.split(' ').where((it) => it == it.toUpperCase()).join(' ');
}
