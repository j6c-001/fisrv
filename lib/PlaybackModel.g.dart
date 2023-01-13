// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'PlaybackModel.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic

mixin _$PlaybackModel on _PlaybackModel, Store {
  final _$timeFactorAtom = Atom(name: '_PlaybackModel.timeFactor');

  @override
  double get timeFactor {
    _$timeFactorAtom.reportRead();
    return super.timeFactor;
  }

  @override
  set timeFactor(double value) {
    _$timeFactorAtom.reportWrite(value, super.timeFactor, () {
      super.timeFactor = value;
    });
  }

  final _$stateAtom = Atom(name: '_PlaybackModel.state');

  @override
  PlaybackState get state {
    _$stateAtom.reportRead();
    return super.state;
  }

  @override
  set state(PlaybackState value) {
    _$stateAtom.reportWrite(value, super.state, () {
      super.state = value;
    });
  }

  @override
  String toString() {
    return '''
timeFactor: ${timeFactor},
state: ${state}
    ''';
  }
}
