import 'package:fisrv/race-visualizer.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import 'PlaybackModel.dart';

RaceVisualizer rv;

void main() async {
  Flame.images.loadAll(<String>[]);

  rv = RaceVisualizer();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {


  @override
  Widget build(BuildContext context) {
    return Provider<PlaybackModel>(
        create: (_) => PlaybackModel(rv),
        builder: (ctx, w) {
          PlaybackModel model = Provider.of<PlaybackModel>(ctx);
        const player = YoutubePlayerIFrame();

          return MaterialApp(
              title: 'FIS Race Replay Simulator',
              theme: ThemeData(
                primarySwatch: Colors.blue,
              ),
              home: YoutubePlayerControllerProvider(

              controller: model.video,
              child: Scaffold(
                body: Row(
                  children: [
                    Expanded(
                    flex:7,
                    child: GameWidget(game: rv),
                    ),
                   Expanded(
                     flex:3,
                     child: player
                   )
                  ],
                ),
                appBar: AppBar(
                  actions: <Widget>[
                    SizedBox(
                        width: 50,
                        child: Center(
                            child: TextFormField(
                          decoration: InputDecoration(
                              labelText: 'Codex', hintText: 'FIS Codex#'),
                        ))),
                    FlatButton(
                      child: Text('Load'),
                      onPressed: () {},
                    ),
                    IconButton(icon: Icon(Icons.zoom_in), onPressed: () {}),
                    IconButton(icon: Icon(Icons.zoom_out), onPressed: () {}),
                    IconButton(
                        icon: Icon(Icons.replay),
                        onPressed: () {
                          model.state = PlaybackState.RESTART;
                        }),
                    IconButton(
                        icon: Icon(Icons.fast_rewind),
                        onPressed: () {
                          model.state = PlaybackState.REWIND;
                        }),
                    Observer(
                      builder: (ctx) => IconButton(
                          icon: Icon(model.state == PlaybackState.PLAY
                              ? Icons.pause
                              : Icons.play_arrow),
                          onPressed: () {
                            model.state = model.state == PlaybackState.PLAY
                                ? PlaybackState.PAUSE
                                : PlaybackState.PLAY;
                          }),
                    ),
                    IconButton(
                        icon: Icon(Icons.fast_forward),
                        onPressed: () {
                          model.state = PlaybackState.FASTFORWARD;
                        })
                  ],
                ),
              )));
        });
  }
}
