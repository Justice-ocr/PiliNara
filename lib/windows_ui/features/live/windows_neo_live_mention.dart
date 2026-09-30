/// Reply target for the Windows live-room side composer.
///
/// The live danmaku API accepts a single reply target, so the composer keeps
/// at most one `@name ` prefix and sends it as `reply_mid` / `replay_dmid`
/// instead of plain text, matching the upstream send sheet.
class WindowsNeoLiveMention {
  const WindowsNeoLiveMention({
    required this.name,
    required this.mid,
    required this.dmid,
  });

  final String name;
  final int mid;
  final String dmid;

  String get prefix => '@$name ';

  /// Composer text after mentioning this user, replacing [previous]'s prefix.
  String applyTo(String text, {WindowsNeoLiveMention? previous}) {
    final body = previous != null && text.startsWith(previous.prefix)
        ? text.substring(previous.prefix.length)
        : text;
    return '$prefix$body';
  }

  /// The message body when the prefix is intact, or null when the user has
  /// edited it away and the text should be sent as a plain danmaku.
  String? bodyOf(String text) =>
      text.startsWith(prefix) ? text.substring(prefix.length) : null;
}
