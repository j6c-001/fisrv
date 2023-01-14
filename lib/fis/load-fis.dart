import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;

import 'race.dart';

Future<Document> getDoc({String url, bool doPrint: false}) async {
  var response = await http.get(url);
  if (doPrint) {
    print(response.body);
  }
  var doc = parse(response.body);
  return doc;
}

class LoadFis {
  final String homologationId;
  final EventRace race;
  Future loader;

  LoadFis(this.homologationId, this.race);

  factory LoadFis.fromHtml(String homologationId) {
    final race = EventRace(name: 'Todo', lapDistance: 0);
    final ret = LoadFis(homologationId, race);

    ret.loader = Future.wait([
      ret._loadRaceInfo(),
      ret._loadStartList(),
      ret._loadSegmentsAndCreateSplits(),
    ]);
    return ret;
  }

  Future _loadRaceInfo() async {
    final doc = await getDoc(
        url:
            'https://www.xcracer.info/api/pt/o2.novius.net/mobile/$homologationId/race-infos-pda.htm');

    final infos = doc.getElementsByClassName('eventinfo');

    if (infos.length > 1) {
      final eventInfos = infos[1].getElementsByTagName('li');
      for (int i = 1; i < eventInfos.length - 1; i++) {
        final item = eventInfos[i];
        final name = item.children[0].text;
        final value = item.children[1].text;
        race.addEventInfo(name, value);
      }
    }
  }

  Future _loadSegmentDefinitions() async {
    final doc = await getDoc(
        url: 'http://live.fis-ski.com/$homologationId/results-pda.htm');
    // load race split segments
    int id = 0;
    doc.getElementById('int1').children.forEach((it) {
      final tkns = it.innerHtml.split(' ');
      final isLastSegment = (tkns.first.toLowerCase() == 'finish');
      final unit = tkns.removeLast().toLowerCase();
      final lengthString = tkns.removeLast(),
          lengthInUnits = double.tryParse(lengthString),
          length = (lengthInUnits ?? 0) * (unit == 'km' ? 1000 : 1);
      if (isLastSegment) {
        id = 99;
      }
      if (length > 0 && id <= 99) {
        race.addOrderedSegment(id, length);
      }

      id++;
    });
  }

  Future _loadStartList() async {
    // load racers

    final doc = await getDoc(
        url:
            'https://www.xcracer.info/api/pt/o2.novius.net/mobile/$homologationId/startlist-pda-1.htm');

    doc.getElementsByClassName('cc')[0].children.forEach((it) {
      var bib = int.parse(it.getElementsByClassName('col_bib')[0].innerHtml),
          name = it.getElementsByClassName('name')[0].text.trim(),
          nation = it.getElementsByClassName('col_nsa')[0].text.trim();
      race.addRacer(bib, RacerDetails(name, nation));
    });
  }

  int noCache = 0;

  Future _updateSplits() async {
    try {
      await Future.forEach(race.segments, (it) async {
        final int segmentId = it.id;
        final doc = await getDoc(
            url:
                'https://www.xcracer.info/api/pt/o2.novius.net/mobile/$homologationId/results-pda-$segmentId.htm');

        doc.getElementsByClassName('cc')[0].children.forEach((it) {
          var bib =
                  int.parse(it.getElementsByClassName('col_bib')[0].innerHtml),
              timeString = it.getElementsByClassName('col_result')[0].innerHtml,
              tkns = timeString.split(':').reversed.toList(),
              ss = double.tryParse(tkns[0]) ?? 0,
              mm = tkns.length > 1 ? int.parse(tkns[1]) : 0,
              hh = tkns.length > 2 ? int.parse(tkns[2]) : 0,
              split = hh * 60 * 60 + mm * 60 + ss;

          if (bib == 64) {
            print('$timeString $segmentId');
          }
          if (split > 0) {
            race.addOrUpdateOrderedSplit(bib, split, segmentId);
          }
        });
      });
    } catch (e) {
      print(e);
    }
  }

  Future _loadSegmentsAndCreateSplits() async {
    await _loadSegmentDefinitions();
    await _updateSplits();
  }
}

//race.removeRacersWithMissingSegments();
