library Decoder;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:utf/utf.dart';

part 'Affix.dart';
part 'AffixType.dart';
part 'Rule.dart';
part 'Word.dart';

class Decoder {
  File _affFile = new File("ru_RU.aff");
  File _dicFile = new File("ru_RU.dic");
  File _outFile = new File("russian.dic");
  IOSink _out;

  Future<Map<String, Affix>> _readAffixes() {
    Completer<Map<String, Affix>> completer = new Completer();

    var stream = _affFile.openRead();
    var stringStream = stream.transform(new Utf8DecoderTransformer()).transform(new LineSplitter());
    Map<String, Affix> affixes = {};
    var subscription;
    subscription = stringStream.listen((String line) {
      line = line.trim();
      if (line.isEmpty) {
        return;
      }

      line = line.replaceFirst(r' ?#.*$', '');
      if (line.isEmpty) {
        return;
      }

      var command = line.split(' ');
      if (command[0] == 'SFX' || command[0] == 'PFX') {
        var type = command[0] == 'SFX' ? AffixType.SUFFIX : AffixType.PREFIX;
        var name = command[1];

        Affix currentAffix = affixes[name];
        if (currentAffix == null) {
          affixes[name] = new Affix(type, name, command[2]);
          return;
        }
        currentAffix.rules.add(new Rule(command[2], command[3], command[4]));
        if (command[5]) {
          completer.completeError('Error in line: ' + line);
          subscription.cancel();
        }
      }
    }, onDone: () {
      completer.complete(affixes);
    });

    return completer.future;
  }


  Future _convertDictionary(Map<String, Affix> affixes) {
    Completer completer = new Completer();

    var stream = _dicFile.openRead();
    var stringStream = stream.transform(new Utf8DecoderTransformer()).transform(new LineSplitter());
    stringStream.listen((line) {
      line = line.trim();
      if (line.indexOf('/') == -1) {
        try {
          int.parse(line);
        } catch (e) {
          _writeWord(line);
        }

        return;
      }

      Word word = new Word.fromString(line);
      _writeWord(word.toString());
    }, onDone: () {
      completer.complete();
    });
    return completer.future;
  }

  void _writeWord(String word) {
    _out.write(word + "\n");
  }

  void process() {
    _out = _outFile.openWrite();
    _readAffixes()
      .then(_convertDictionary)
      .then((_) => _out.flush)
      .then((_) => _out.close)
      .then((_) => print("Done."));
  }
}