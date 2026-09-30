import 'package:PiliPlus/windows_ui/features/live/windows_neo_live_mention.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const alice = WindowsNeoLiveMention(name: 'alice', mid: 1, dmid: 'a1');
  const bob = WindowsNeoLiveMention(name: 'bob', mid: 2, dmid: 'b2');

  test('prefixes the composer text with the mention', () {
    expect(alice.applyTo(''), '@alice ');
    expect(alice.applyTo('hello'), '@alice hello');
  });

  test('replaces the previous mention instead of stacking prefixes', () {
    final first = alice.applyTo('hello');
    expect(bob.applyTo(first, previous: alice), '@bob hello');
  });

  test('keeps text when the previous prefix was edited away', () {
    expect(bob.applyTo('hello', previous: alice), '@bob hello');
  });

  test('extracts the reply body only while the prefix is intact', () {
    expect(alice.bodyOf('@alice hi'), 'hi');
    expect(alice.bodyOf('@alice '), '');
    expect(alice.bodyOf('@alic hi'), isNull);
    expect(alice.bodyOf('hi'), isNull);
  });
}
