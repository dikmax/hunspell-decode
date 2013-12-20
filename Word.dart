part of Decoder;

class Word {
  String word;
  HashSet<String> affixesStrings;
  Map<String, Affix> affixes = {};

  static String _parseWord(String line) {
    var slashPos = line.indexOf('/');
    if (slashPos == -1) {
      return line;
    }
    return line.substring(0, slashPos);
  }

  static HashSet<String> _parseAffixesToStrings(String line) {
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

  Word(this.word, this.affixesStrings) {
    affixesStrings.forEach((affix) {
      if (Affix.affixes[affix] != null) {
        affixes[affix] = Affix.affixes[affix];
      }
    });
  }

  Word.fromString(String line): this(_parseWord(line), _parseAffixesToStrings(line));

  HashSet<String> convert() {
    HashSet<String> result = new HashSet.from([word]);

    affixes.forEach((flag, affix) {
      HashSet<String> newWords = _applyAffix(new HashSet.from([word]), affix);
      result = result.union(newWords);
    });

    return result;
  }

  RegExp _getRegExp(Affix affix, condition) {
    return new RegExp(affix.type == AffixType.PREFIX ? '^' + condition : condition + '\$');
  }

  HashSet<String> _getSupplementAffixes(Affix excludeAffix, [HashSet<String> additional = null]) {
    HashSet<String> result = new HashSet.identity();

    affixes.forEach((flag, affix) {
      if (affix.type != excludeAffix.type) {
        result.add(flag);
      }
    });

    if (additional != null) {
      result = result.union(additional);
    }

    return result;
  }

  HashSet<String> _applyAffix(HashSet<String> words, Affix affix) {
    HashSet<String> result = new HashSet.identity();

    words.forEach((word) {
      affix.rules.forEach((rule) {
        String replace = _parseWord(rule.affix);
        String newWord = word;
        RegExp condition = _getRegExp(affix, rule.condition);
        if (rule.condition == '0' || condition.hasMatch(newWord)) {
          if (rule.remove != '0') {
            newWord = newWord.replaceFirst(_getRegExp(affix, rule.remove), '');
          }
          if (replace != '0') {
            if (affix.type == AffixType.PREFIX) {
              newWord = replace + newWord;
            } else {
              newWord = newWord + replace;
            }
          }
        } else {
          return;
        }

        result.add(newWord);

        HashSet<String> flags = _getSupplementAffixes(affix, _parseAffixesToStrings(rule.affix));
        if (flags.length > 0) {
          Word subWord = new Word(newWord, flags);
          result = result.union(subWord.convert());
        }
      });
    });

    return result;
  }

  String toString() {
    return word + "[" + affixesStrings.join(',') + "]";
  }
}