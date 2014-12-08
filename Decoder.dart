library Decoder;

import 'dart:async';
import 'dart:collection';
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
  int _wordsCount = 0;
  IOSink _out;

  Future _readAffixes() {
    Completer<Map<String, Affix>> completer = new Completer();

    var stream = _affFile.openRead();
    var stringStream = stream.transform(new Utf8DecoderTransformer()).transform(new LineSplitter());
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

        Affix currentAffix = Affix.affixes[name];
        if (currentAffix == null) {
          Affix.affixes[name] = new Affix(type, name, command[2]);
          return;
        }
        currentAffix.rules.add(new Rule(command[2], command[3], command[4]));
      }
    }, onDone: () {
      completer.complete(true);
    });

    return completer.future;
  }


  Future _convertDictionary(_) {
    Completer completer = new Completer();

    var stream = _dicFile.openRead();
    var stringStream = stream.transform(new Utf8DecoderTransformer()).transform(new LineSplitter());
    int totalCount = 0;
    int currentLine = 0;
    List<String> wordsList = [];
    stringStream.listen((line) {
      line = line.trim();
      ++currentLine;
      if (currentLine & 127 == 127) {
        print("$currentLine or $totalCount processed...");
      }
      if (line.indexOf('/') == -1) {
        try {
          int i = int.parse(line);
          totalCount = i;
        } catch (e) {
          wordsList.add(line);
        }

        return;
      }

      Word word = new Word.fromString(line);
      wordsList.addAll(word.convert());
    }, onDone: () {
      print("Sorting...");
      wordsList.sort();
      String prevWord = '';
      print("Writing...");
      wordsList.forEach((word) {
        if (word == prevWord) {
          return;
        }
        prevWord = word;
        _writeWord(word);
      });
      completer.complete();
    });
    return completer.future;
  }

  void _writeWord(String word) {
    ++_wordsCount;
    _out.writeln(word);
  }

  void process() {
    _out = _outFile.openWrite();
    _readAffixes()
      .then(_convertDictionary)
      .then((_) => _out.flush)
      .then((_) => _out.close)
      .then((_) => print("${_wordsCount} words written. Done."));
  }
}