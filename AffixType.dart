part of Decoder;

class AffixType {
  static const PREFIX = const AffixType._(0);
  static const SUFFIX = const AffixType._(1);

  static get values => [PREFIX, SUFFIX];

  final int value;

  const AffixType._(this.value);
}
