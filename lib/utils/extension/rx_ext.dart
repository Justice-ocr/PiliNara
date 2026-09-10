import 'package:get/get_rx/src/rx_types/rx_types.dart' show RxList;

extension RxListExt<E> on RxList<E> {
  void fillRangeOnly(int start, int end, [E? fill]) {
    E fillValue = fill as E;
    final items = value;
    for (int i = start; i < end; i++) {
      items[i] = fillValue;
    }
  }
}
