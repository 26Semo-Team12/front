// test/features/home/views/filter_button_test.dart
// FilterButton 위젯 테스트
// 검증 대상: 요구사항 6.2, 6.3

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:front/features/home/models/invitation.dart';
import 'package:front/features/home/views/home_screen_widgets.dart';

void main() {
  group('FilterButton: 선택/비선택 상태', () {
    testWidgets('선택 상태일 때 배경색이 Color(0xFFD6706D)이고 텍스트가 흰색', (tester) async {
      // Validates: Requirements 6.2, 6.3
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterButton(
              label: '새 초대장',
              type: InvitationType.newInvitation,
              isSelected: true,
              onTap: () {},
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(FilterButton),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(const Color(0xFFD6706D)));

      final text = tester.widget<Text>(find.text('새 초대장'));
      expect(text.style?.color, equals(Colors.white));
    });

    testWidgets('비선택 상태일 때 배경색이 흰색이고 테두리가 있음', (tester) async {
      // Validates: Requirements 6.2, 6.3
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterButton(
              label: '장기 모임',
              type: InvitationType.longTerm,
              isSelected: false,
              onTap: () {},
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(FilterButton),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(Colors.white));
      expect(decoration.border, isNotNull);
    });

    testWidgets('onTap 콜백이 탭 시 호출됨', (tester) async {
      // Validates: Requirements 6.2
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterButton(
              label: '만료된 초대장',
              type: InvitationType.expired,
              isSelected: false,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('만료된 초대장'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('borderRadius가 20인지 확인', (tester) async {
      // Validates: Requirements 6.3
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterButton(
              label: '새 초대장',
              type: InvitationType.newInvitation,
              isSelected: false,
              onTap: () {},
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(FilterButton),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(
        decoration.borderRadius,
        equals(BorderRadius.circular(20)),
      );
    });
  });
}
