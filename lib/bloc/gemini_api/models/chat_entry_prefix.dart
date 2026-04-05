enum ChatEntryPrefix {
  prompt('Prompt: '),
  aiReply('AI reply: '),
  error('Error: ');

  final String value;

  const ChatEntryPrefix(this.value);

  /// 將 [content] 加上此前綴。
  String wrap(String content) => '$value$content';

  /// 如果 [entry] 以此前綴開頭，則返回 true。
  bool matches(String entry) => entry.startsWith(value);

  /// 從 [entry] 中移除此前綴。如果不是以此前綴開頭，則返回原字串。
  String strip(String entry) =>
      entry.startsWith(value) ? entry.substring(value.length) : entry;

  /// 偵測 [entry] 的前綴並返回對應的 [ChatEntryPrefix]，
  /// 若無匹配則返回 null。
  static ChatEntryPrefix? of(String entry) {
    for (final p in ChatEntryPrefix.values) {
      if (entry.startsWith(p.value)) return p;
    }
    return null;
  }
}
