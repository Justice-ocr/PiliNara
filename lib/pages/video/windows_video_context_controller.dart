import 'package:PiliPlus/grpc/bilibili/main/community/reply/v1.pb.dart'
    show ReplyInfo;

sealed class WindowsVideoContextEntry {
  const WindowsVideoContextEntry();

  String get id;
  String get title;
}

final class WindowsVideoMemberContext extends WindowsVideoContextEntry {
  const WindowsVideoMemberContext({required this.mid});

  final int mid;

  @override
  String get id => 'member:$mid';

  @override
  String get title => 'UP 主主页';
}

final class WindowsVideoReplyContext extends WindowsVideoContextEntry {
  const WindowsVideoReplyContext({required this.replyItem, this.replyId});

  final ReplyInfo replyItem;
  final int? replyId;

  @override
  String get id => 'reply:${replyItem.id}:$replyId';

  @override
  String get title => '评论详情';
}

class WindowsVideoContextController {
  final List<WindowsVideoContextEntry> _history = [];

  WindowsVideoContextEntry? get current =>
      _history.isEmpty ? null : _history.last;
  List<WindowsVideoContextEntry> get entries =>
      List<WindowsVideoContextEntry>.unmodifiable(_history);
  bool get canPop => _history.isNotEmpty;
  int get depth => _history.length;

  void push(WindowsVideoContextEntry entry) {
    if (_history.isNotEmpty && _history.last.id == entry.id) {
      _history[_history.length - 1] = entry;
      return;
    }
    _history.add(entry);
  }

  WindowsVideoContextEntry? pop() {
    if (_history.isEmpty) return null;
    return _history.removeLast();
  }

  List<WindowsVideoContextEntry> clear() {
    final removed = List<WindowsVideoContextEntry>.of(_history.reversed);
    _history.clear();
    return removed;
  }
}
