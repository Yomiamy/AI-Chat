enum ChatEntryPrefix {
  prompt('Prompt: '),
  aiReply('AI reply: '),
  error('Error: ');

  final String value;

  const ChatEntryPrefix(this.value);

  /// Wraps [content] with this prefix.
  String wrap(String content) => '$value$content';

  /// Returns true if [entry] starts with this prefix.
  bool matches(String entry) => entry.startsWith(value);

  /// Strips this prefix from [entry]. Returns [entry] unchanged if it does
  /// not start with this prefix.
  String strip(String entry) =>
      entry.startsWith(value) ? entry.substring(value.length) : entry;

  /// Detects the prefix of [entry] and returns the matching [ChatEntryPrefix],
  /// or null if none matches.
  static ChatEntryPrefix? of(String entry) {
    for (final p in ChatEntryPrefix.values) {
      if (entry.startsWith(p.value)) return p;
    }
    return null;
  }
}
