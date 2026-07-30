import 'package:PiliPlus/windows_ui/features/video/windows_neo_video_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses a side panel only when both desktop constraints are met', () {
    expect(WindowsNeoVideoLayout.useSidePanel(960, 560), isTrue);
    expect(WindowsNeoVideoLayout.useSidePanel(959, 700), isFalse);
    expect(WindowsNeoVideoLayout.useSidePanel(1200, 559), isFalse);
  });

  test('clamps the side panel to its supported desktop width', () {
    expect(
      WindowsNeoVideoLayout.sidePanelWidth(1000, visible: true),
      360,
    );
    expect(
      WindowsNeoVideoLayout.sidePanelWidth(2000, visible: true),
      460,
    );
    expect(
      WindowsNeoVideoLayout.sidePanelWidth(1400, visible: false),
      0,
    );
  });

  test('routes member pages into the Windows context panel when it fits', () {
    expect(
      WindowsNeoVideoLayout.memberPresentation(
        windowsNeoEnabled: true,
        usesSidePanel: true,
        isPortrait: false,
        horizontalMemberPage: false,
      ),
      WindowsVideoMemberPresentation.sidePanel,
    );
    expect(
      WindowsNeoVideoLayout.memberPresentation(
        windowsNeoEnabled: true,
        usesSidePanel: false,
        isPortrait: false,
        horizontalMemberPage: true,
      ),
      WindowsVideoMemberPresentation.fullPage,
    );
  });

  test('keeps the legacy non-Windows member presentation rules', () {
    expect(
      WindowsNeoVideoLayout.memberPresentation(
        windowsNeoEnabled: false,
        usesSidePanel: false,
        isPortrait: false,
        horizontalMemberPage: true,
      ),
      WindowsVideoMemberPresentation.horizontalSheet,
    );
    expect(
      WindowsNeoVideoLayout.memberPresentation(
        windowsNeoEnabled: false,
        usesSidePanel: true,
        isPortrait: true,
        horizontalMemberPage: true,
      ),
      WindowsVideoMemberPresentation.fullPage,
    );
  });

  test('keeps player heights inside their workspace allocation', () {
    expect(WindowsNeoVideoLayout.widePlayerHeight(1280, 800), 528);
    expect(WindowsNeoVideoLayout.compactPlayerHeight(800, 900), 450);
  });
}
