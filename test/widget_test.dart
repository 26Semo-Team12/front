// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:front/main.dart';

void main() {
  testWidgets('앱이 정상적으로 시작됨', (WidgetTester tester) async {
    await tester.pumpWidget(const VentureApp());
    // pump once without settling to avoid waiting for network images
    await tester.pump();
    // Drain any image-load exceptions (network returns 400 in test env)
    tester.takeException();
    // 앱이 오류 없이 렌더링되는지 확인
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
