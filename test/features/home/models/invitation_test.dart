// test/features/home/models/invitation_test.dart

import 'dart:math';
import 'package:test/test.dart';
import 'package:front/features/home/models/invitation.dart';

void main() {
  // Feature: home-screen-interactions, Property 8: 초대장 목록 정렬 순서 불변
  group('Property 8: 초대장 목록 정렬 순서 불변', () {
    final random = Random(42);

    Invitation makeInvitation(String id, InvitationType type) {
      return Invitation(
        id: id,
        type: type,
        title: 'Title $id',
        dateTime: DateTime(2024, 1, 1),
        location: 'Location $id',
        memberCount: 1,
      );
    }

    List<Invitation> randomInvitations(Random rng, int count) {
      final types = InvitationType.values;
      return List.generate(count, (i) {
        final type = types[rng.nextInt(types.length)];
        return makeInvitation('$i', type);
      });
    }

    test('임의의 Invitation 목록을 type.index 오름차순으로 정렬하면 순서가 유지됨 (100회 반복)', () {
      // Validates: Requirements 6.7
      for (int iteration = 0; iteration < 100; iteration++) {
        final count = random.nextInt(20); // 0~19개
        final invitations = randomInvitations(random, count);

        final sorted = List<Invitation>.from(invitations)
          ..sort((a, b) => a.type.index.compareTo(b.type.index));

        // 정렬 후 인접한 두 항목의 type.index가 오름차순임을 검증
        for (int i = 0; i < sorted.length - 1; i++) {
          expect(
            sorted[i].type.index <= sorted[i + 1].type.index,
            isTrue,
            reason:
                'iteration=$iteration, index=$i: ${sorted[i].type} (${sorted[i].type.index}) should be <= ${sorted[i + 1].type} (${sorted[i + 1].type.index})',
          );
        }
      }
    });

    test('정렬 결과는 newInvitation → longTerm → expired 순서를 따름 (100회 반복)', () {
      // Validates: Requirements 6.7
      for (int iteration = 0; iteration < 100; iteration++) {
        final count = random.nextInt(15) + 1; // 1~15개
        final invitations = randomInvitations(random, count);

        final sorted = List<Invitation>.from(invitations)
          ..sort((a, b) => a.type.index.compareTo(b.type.index));

        // newInvitation이 longTerm보다 앞에 위치
        // longTerm이 expired보다 앞에 위치
        bool seenLongTerm = false;
        bool seenExpired = false;

        for (final inv in sorted) {
          if (inv.type == InvitationType.longTerm) seenLongTerm = true;
          if (inv.type == InvitationType.expired) seenExpired = true;

          if (inv.type == InvitationType.newInvitation) {
            expect(seenLongTerm, isFalse,
                reason:
                    'iteration=$iteration: newInvitation은 longTerm보다 앞에 있어야 함');
            expect(seenExpired, isFalse,
                reason:
                    'iteration=$iteration: newInvitation은 expired보다 앞에 있어야 함');
          }
          if (inv.type == InvitationType.longTerm) {
            expect(seenExpired, isFalse,
                reason:
                    'iteration=$iteration: longTerm은 expired보다 앞에 있어야 함');
          }
        }
      }
    });

    test('빈 목록 정렬은 빈 목록을 반환함', () {
      // Validates: Requirements 6.7
      final sorted = <Invitation>[]
        ..sort((a, b) => a.type.index.compareTo(b.type.index));
      expect(sorted, isEmpty);
    });

    test('단일 항목 목록 정렬은 동일한 항목을 반환함', () {
      // Validates: Requirements 6.7
      for (final type in InvitationType.values) {
        final inv = makeInvitation('single', type);
        final sorted = [inv]
          ..sort((a, b) => a.type.index.compareTo(b.type.index));
        expect(sorted.length, equals(1));
        expect(sorted.first.type, equals(type));
      }
    });
  });
}
