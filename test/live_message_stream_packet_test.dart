import 'dart:convert';
import 'dart:typed_data';

import 'package:PiliPlus/tcp/live.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Uint8List messageFrame(
    Map<String, Object> payload, {
    int headerSize = 16,
  }) {
    final body = Uint8List.fromList(
      const Utf8Encoder().convert(jsonEncode(payload)),
    );
    final frame = Uint8List(headerSize + body.length);
    ByteData.sublistView(frame)
      ..setUint32(0, frame.length, Endian.big)
      ..setUint16(4, headerSize, Endian.big)
      ..setUint16(6, 1, Endian.big)
      ..setUint32(8, 5, Endian.big)
      ..setUint32(12, 1, Endian.big);
    frame.setRange(headerSize, frame.length, body);
    return frame;
  }

  Uint8List packet({
    int totalSize = 16,
    int headerSize = 16,
    int protocolVer = 1,
    int operationCode = 5,
    int seq = 7,
    int length = 16,
  }) {
    final bytes = Uint8List(length);
    if (length >= 16) {
      ByteData.sublistView(bytes)
        ..setUint32(0, totalSize, Endian.big)
        ..setUint16(4, headerSize, Endian.big)
        ..setUint16(6, protocolVer, Endian.big)
        ..setUint32(8, operationCode, Endian.big)
        ..setUint32(12, seq, Endian.big);
    }
    return bytes;
  }

  group('PackageHeaderRes.fromBytesData', () {
    test('parses a complete 16-byte header', () {
      final header = PackageHeaderRes.fromBytesData(packet());

      expect(header, isNotNull);
      expect(header!.totalSize, 16);
      expect(header.headerSize, 16);
      expect(header.protocolVer, 1);
      expect(header.operationCode, 5);
      expect(header.seq, 7);
    });

    test('rejects truncated headers and inconsistent packet lengths', () {
      expect(
        PackageHeaderRes.fromBytesData(packet(length: 15)),
        isNull,
      );
      expect(
        PackageHeaderRes.fromBytesData(packet(totalSize: 32)),
        isNull,
      );
      expect(
        PackageHeaderRes.fromBytesData(packet(totalSize: 15)),
        isNull,
      );
      expect(
        PackageHeaderRes.fromBytesData(packet(headerSize: 15)),
        isNull,
      );
      expect(
        PackageHeaderRes.fromBytesData(packet(headerSize: 20)),
        isNull,
      );
    });

    test('processes every complete frame in a coalesced socket event', () {
      final received = <dynamic>[];
      final stream = LiveMessageStream(
        streamToken: 'token',
        roomId: 1,
        uid: 2,
        servers: const [],
      )..addEventListener(received.add);
      final first = messageFrame({'id': 1});
      final second = messageFrame({'id': 2});
      final coalesced = Uint8List(first.length + second.length)
        ..setRange(0, first.length, first)
        ..setRange(first.length, first.length + second.length, second);

      stream.onData(coalesced);

      expect(received, [
        {'id': 1},
        {'id': 2},
      ]);
      stream.close(notify: false);
    });

    test('notifies once when socket data has a malformed header', () {
      var closedCount = 0;
      final stream = LiveMessageStream(
        streamToken: 'token',
        roomId: 1,
        uid: 2,
        servers: const [],
        onClosed: () => closedCount++,
      )..addEventListener((_) {});

      stream.onData(packet(totalSize: 32));
      stream.close();

      expect(closedCount, 1);
    });

    test('processes payload after an extended packet header', () {
      final received = <dynamic>[];
      final stream = LiveMessageStream(
        streamToken: 'token',
        roomId: 1,
        uid: 2,
        servers: const [],
      )..addEventListener(received.add);
      final frame = messageFrame({'id': 3}, headerSize: 20);

      stream.onData(frame);

      expect(received, [
        {'id': 3},
      ]);
      stream.close(notify: false);
    });
  });
}
