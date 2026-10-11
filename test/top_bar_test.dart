import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:window_manager/window_manager.dart';

import 'fake_backend.dart';
import 'helpers.dart';

void main() {
  const channel = MethodChannel('window_manager');
  final calls = <String>[];
  bool maximized = false;

  setUp(() {
    calls.clear();
    maximized = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      if (call.method == 'isMaximized') return maximized;
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('traffic lights drive window actions', (tester) async {
    await tester.pumpWidget(testApp(FakeBackend()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('traffic-close')));
    await tester.tap(find.byKey(const ValueKey('traffic-min')));
    await tester.tap(find.byKey(const ValueKey('traffic-max')));
    await tester.pump();

    expect(calls, ['close', 'minimize', 'isMaximized', 'maximize']);
  });

  testWidgets('maximize toggles back when maximized', (tester) async {
    maximized = true;
    await tester.pumpWidget(testApp(FakeBackend()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('traffic-max')));
    await tester.pump();
    expect(calls, ['isMaximized', 'unmaximize']);
  });

  testWidgets('hover reveals the glyph', (tester) async {
    await tester.pumpWidget(testApp(FakeBackend()));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.close), findsNothing);

    final mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse);
    await mouse.addPointer(
        location: tester.getCenter(
            find.byKey(const ValueKey('traffic-close'))));
    await tester.pump();
    expect(find.byIcon(Icons.close), findsOneWidget);

    await mouse.moveTo(Offset.zero);
    await tester.pump();
    expect(find.byIcon(Icons.close), findsNothing);
    await mouse.removePointer();
  });

  testWidgets('double tap on the title bar maximizes', (tester) async {
    await tester.pumpWidget(testApp(FakeBackend()));
    await tester.pumpAndSettle();

    final area = find.byType(DragToMoveArea);
    await tester.tap(area);
    await tester.pump(kDoubleTapMinTime);
    await tester.pump(const Duration(milliseconds: 30));
    await tester.tap(area);
    await tester.pump();
    expect(calls, containsAll(['isMaximized', 'maximize']));
    await tester.pump(kDoubleTapTimeout);
  });
}
