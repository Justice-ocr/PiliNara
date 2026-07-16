import 'package:PiliPlus/windows_ui/features/dynamics/windows_neo_dynamics_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chooses responsive Windows dynamics waterfall columns', () {
    expect(WindowsNeoDynamicsLayout.crossAxisCount(819), 1);
    expect(WindowsNeoDynamicsLayout.crossAxisCount(820), 2);
    expect(WindowsNeoDynamicsLayout.crossAxisCount(1199), 2);
    expect(WindowsNeoDynamicsLayout.crossAxisCount(1200), 3);
  });

  test('centers wide dynamics content without losing minimum padding', () {
    expect(WindowsNeoDynamicsLayout.horizontalPadding(1000), 18);
    expect(WindowsNeoDynamicsLayout.horizontalPadding(1600), 110);
  });
}
