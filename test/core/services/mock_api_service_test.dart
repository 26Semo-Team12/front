// test/core/services/mock_api_service_test.dart
// Feature: home-screen-interactions, Property 11: MockAPI 프로필 수정 라운드 트립

import 'dart:math';
import 'package:test/test.dart';
import 'package:front/core/services/mock_api_service.dart';

/// 비어있지 않은 임의의 문자열 생성
String _randomNonEmptyString(Random rng, {int maxLength = 20}) {
  const chars = 'abcdefghijklmnopqrstuvwxyz가나다라마바사아자차카타파하';
  final length = rng.nextInt(maxLength) + 1;
  return List.generate(length, (_) => chars[rng.nextInt(chars.length)]).join();
}

/// 임의의 태그 목록 생성 (0~5개)
List<String> _randomTagList(Random rng) {
  final count = rng.nextInt(6);
  return List.generate(count, (_) => _randomNonEmptyString(rng, maxLength: 10));
}

/// 임의의 URL 생성
String _randomUrl(Random rng) {
  final seed = rng.nextInt(10000);
  return 'https://picsum.photos/seed/$seed/200';
}

void main() {
  final random = Random(42);

  // ─────────────────────────────────────────────
  // 속성 11: MockAPI 프로필 수정 라운드 트립 (Property-Based Test)
  // ─────────────────────────────────────────────
  group('Property 11: MockAPI 프로필 수정 라운드 트립', () {
    test('임의의 유효한 수정 데이터로 patchMe 후 getMe 결과가 수정된 데이터와 일치함 (100회 반복)', () async {
      // Validates: Requirements 10.2
      for (int i = 0; i < 100; i++) {
        // 각 반복마다 새 인스턴스 생성 (상태 격리)
        final service = MockApiService();

        final newName = _randomNonEmptyString(random);
        final newImageUrl = _randomUrl(random);
        final newInterests = _randomTagList(random);

        await service.patchMe(
          name: newName,
          profileImageUrl: newImageUrl,
          interests: newInterests,
        );

        final result = await service.getMe();

        expect(
          result.name,
          equals(newName),
          reason: 'iteration=$i: patchMe(name: "$newName") 후 getMe().name이 일치해야 함',
        );
        expect(
          result.profileImageUrl,
          equals(newImageUrl),
          reason: 'iteration=$i: patchMe(profileImageUrl: "$newImageUrl") 후 getMe().profileImageUrl이 일치해야 함',
        );
        expect(
          result.interests,
          equals(newInterests),
          reason: 'iteration=$i: patchMe(interests: $newInterests) 후 getMe().interests가 일치해야 함',
        );
      }
    });

    test('patchMe에서 일부 필드만 수정 시 나머지 필드는 유지됨 (100회 반복)', () async {
      // Validates: Requirements 10.2
      for (int i = 0; i < 100; i++) {
        final service = MockApiService();

        // 초기 상태 저장
        final original = await service.getMe();
        final newName = _randomNonEmptyString(random);

        // name만 수정
        await service.patchMe(name: newName);
        final result = await service.getMe();

        expect(
          result.name,
          equals(newName),
          reason: 'iteration=$i: name만 수정 후 name이 일치해야 함',
        );
        expect(
          result.profileImageUrl,
          equals(original.profileImageUrl),
          reason: 'iteration=$i: name만 수정 시 profileImageUrl은 유지되어야 함',
        );
        expect(
          result.interests,
          equals(original.interests),
          reason: 'iteration=$i: name만 수정 시 interests는 유지되어야 함',
        );
        expect(
          result.rating,
          equals(original.rating),
          reason: 'iteration=$i: rating은 patchMe로 변경되지 않아야 함',
        );
      }
    });
  });

  // ─────────────────────────────────────────────
  // MockApiService 단위 테스트
  // ─────────────────────────────────────────────
  group('MockApiService 단위 테스트', () {
    test('getMe는 기본 UserProfile을 반환함', () async {
      final service = MockApiService();
      final profile = await service.getMe();

      expect(profile.name, isNotEmpty);
      expect(profile.profileImageUrl, isNotEmpty);
      expect(profile.interests, isNotNull);
    });

    test('patchMe는 수정된 UserProfile을 반환함', () async {
      final service = MockApiService();

      final updated = await service.patchMe(name: '새이름');

      expect(updated.name, equals('새이름'));
    });

    test('patchMe 후 getMe는 동일한 수정된 프로필을 반환함', () async {
      final service = MockApiService();

      await service.patchMe(
        name: '테스트유저',
        profileImageUrl: 'https://example.com/new.jpg',
        interests: ['음악', '영화'],
      );

      final result = await service.getMe();

      expect(result.name, equals('테스트유저'));
      expect(result.profileImageUrl, equals('https://example.com/new.jpg'));
      expect(result.interests, equals(['음악', '영화']));
    });

    test('각 MockApiService 인스턴스는 독립적인 상태를 가짐', () async {
      final service1 = MockApiService();
      final service2 = MockApiService();

      await service1.patchMe(name: '유저1');
      await service2.patchMe(name: '유저2');

      final result1 = await service1.getMe();
      final result2 = await service2.getMe();

      expect(result1.name, equals('유저1'));
      expect(result2.name, equals('유저2'));
    });
  });
}
