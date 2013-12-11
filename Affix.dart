part of Decoder;

class Affix {
  final AffixType type;
  final String name;
  final String connection;
  final List<Rule> rules = [];

  Affix(this.type, this.name, this.connection);

  void addRule(Rule rule) {
    rules.add(rule);
  }
}
