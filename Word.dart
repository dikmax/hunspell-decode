part of Decoder;

class Word {
  String word;
  HashSet<String> affixes;
  Map<String, Affix> prefixes = {};
  Map<String, Affix> suffixes = {};

  static String _parseWord(String line) {
    var slashPos = line.indexOf('/');
    if (slashPos == -1) {
      return line;
    }
    return line.substring(0, slashPos);
  }

  static HashSet<String> _parseAffixes(String line) {
    var slashPos = line.indexOf('/');
    var result = new HashSet.identity();
    if (slashPos == -1) {
      return result;
    }

    String affixesString = line.substring(slashPos + 1);
    while (!affixesString.isEmpty) {
      result.add(affixesString.substring(0, 2));
      affixesString = affixesString.substring(2);
    }

    return result;
  }

  Word.fromString(String line) {
    word = _parseWord(line);
    affixes = _parseAffixes(line);

    affixes.forEach((affix) {
      if (Affix.affixes[affix] != null) {
        if (Affix.affixes[affix].type == AffixType.PREFIX) {
          prefixes[affix] = Affix.affixes[affix];
        } else {
          suffixes[affix] = Affix.affixes[affix];
        }
      }
    });
  }

  List<String> convert() {
    HashSet<String> result = new HashSet.from([word]);

    // TODO check артикулировав0
    suffixes.forEach((flag, suffix) {
      HashSet<String> newWords = _applySuffix(new HashSet.from([word]), suffix);
      result = result.union(newWords);
      prefixes.forEach((_, prefix) {
        result = result.union(_applyPrefix(newWords, prefix, flag));
      });
    });

    prefixes.forEach((flag, prefix) {
      HashSet<String> newWords = _applySuffix(new HashSet.from([word]), prefix);
      result = result.union(newWords);
      suffixes.forEach((_, suffix) {
        result = result.union(_applyPrefix(newWords, suffix, flag));
      });
    });

    print(result);

    return result.toList();
  }

  HashSet<String> _applyPrefix(HashSet<String> words, Affix prefix, [String suffixFlag = null]) {
    HashSet<String> result = new HashSet.identity();
    words.forEach((word) {
      prefix.rules.forEach((rule) {
        HashSet<String> flags = _parseAffixes(rule.affix);
        if (flags.length > 0) {
          if (suffixFlag != null && !flags.contains(suffixFlag) || suffixFlag == null) {
            return;
          }
        }
        String replace = _parseWord(rule.affix);
        String newWord = word;
        RegExp condition = new RegExp('^' + rule.condition);
        if (rule.condition == '.' || condition.hasMatch(newWord)) {
          if (rule.remove != '.') {
            newWord = newWord.replaceFirst(new RegExp('^' + rule.remove), '');
          }
          if (replace != '.') {
            newWord = replace + newWord;
          }
        } else {
          return;
        }

        result.add(newWord);
      });
    });

    return result;
  }

  HashSet<String> _applySuffix(HashSet<String> words, Affix suffix, [String prefixFlag = null]) {
    HashSet<String> result = new HashSet.identity();
    words.forEach((word) {
      suffix.rules.forEach((rule) {
        HashSet<String> flags = _parseAffixes(rule.affix);
        if (flags.length > 0) {
          if (prefixFlag != null && !flags.contains(prefixFlag) || prefixFlag == null) {
            return;
          }
        }
        String replace = _parseWord(rule.affix);
        String newWord = word;
        RegExp condition = new RegExp(rule.condition + '\$');
        if (rule.condition == '.' || condition.hasMatch(newWord)) {
          if (rule.remove != '.') {
            newWord = newWord.replaceFirst(new RegExp(rule.remove + '\$'), '');
          }
          if (replace != '.') {
            newWord += replace;
          }
        } else {
          return;
        }

        result.add(newWord);
      });
    });

    return result;
  }

  String toString() {
    return word + "[" + affixes.join(',') + "]";
  }
}