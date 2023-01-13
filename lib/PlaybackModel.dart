import 'package:fisrv/race-visualizer.dart';
import 'package:mobx/mobx.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

part 'PlaybackModel.g.dart';

class PlaybackModel = _PlaybackModel with _$PlaybackModel;

const ZeroTime = Duration();

enum PlaybackState { RESTART, PLAY, REWIND, FASTFORWARD, PAUSE }

abstract class _PlaybackModel with Store {
  ReactionDisposer sv;
  RaceVisualizer rv;



  _PlaybackModel(RaceVisualizer rv) {
    rv.pbm = this;
    sv =
        reaction((_) => [timeFactor, state], (v)  {
          rv.newPlaybackState = v[1];
          if(v[1] == PlaybackState.PLAY) {
            video.seekTo(Duration(seconds: 17 + rv.raceManager.time.truncate()));
            video.play();
          } else {
            video.pause();
          }
        });
  }

  YoutubePlayerController video = YoutubePlayerController(
    initialVideoId: 'JGIdYIqOPXE',
    params: YoutubePlayerParams(
        autoPlay: true,
        mute: false,
        showControls: false,
      desktopMode: true,

    ),
  );

  void dispose() {
    sv();
  }

  @observable
  double timeFactor;

  @observable
  PlaybackState state;
}
