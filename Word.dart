part of Decoder;

class Word {
  String word;
  List<String> affixes;

  Word.fromString(String line) {
    var slashPos = line.indexOf('/');
    word = line.substring(0, slashPos);
    String affixesString = line.substring(slashPos + 1);
    affixes = [];
    while (!affixesString.isEmpty) {
      affixes.add(affixesString.substring(0, 2));
      affixesString = affixesString.substring(2);
    }
  }

  String toString() {
    return word + "[" + affixes.join(',') + "]";
  }
}