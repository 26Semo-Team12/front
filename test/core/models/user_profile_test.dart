// test/core/models/user_profile_test.dart
// Feature: home-screen-interactions, Property 5: 이름 업데이트 반영
// Feature: profile-tag-system, Property 2: LocationModel 직렬화 라운드트립

import 'dart:math';
import 'package:glados/glados.dart';
import 'package:test/test.dart';
import 'package:front/core/models/user_profile.dart';

UserProfile _makeProfile({
  String name = '홍길동',
  String profileImageUrl = 'https://example.com/image.jpg',
  List<String>? interests,
  String? ageRange = '20대',
  String? gender = '남성',
  double rating = 4.5,
}) {
  return UserProfile(
    name: name,
    profileImageUrl: profileImageUrl,
    locations: [],
    availableTimes: [],
    interests: interests ?? ['독서', '여행'],
    ageRange: ageRange,
    gender: gender,
    rating: rating,
  );
}

/// 비어있지 않은 임의의 문자열 생성
String _randomNonEmptyString(Random rng, {int maxLength = 20}) {
  const chars = 'abcdefghijklmnopqrstuvwxyz가나다라마바사아자차카타파하';
  final length = rng.nextInt(maxLength) + 1;
  return List.generate(length, (_) => chars[rng.nextInt(chars.length)]).join();
}

void main() {
  final random = Random(42);

  // ─────────────────────────────────────────────
  // 속성 5: 이름 업데이트 반영 (Property-Based Test)
  // ─────────────────────────────────────────────
  group('Property 5: 이름 업데이트 반영', () {
    test('임의의 유효한 이름으로 copyWith 후 name이 해당 값과 일치함 (100회 반복)', () {
      // Validates: Requirements 2.2
      for (int i = 0; i < 100; i++) {
        final original = _makeProfile();
        final newName = _randomNonEmptyString(random);

        final updated = original.copyWith(name: newName);

        expect(
          updated.name,
          equals(newName),
          reason: 'iteration=$i: copyWith(name: "$newName") 후 name이 일치해야 함',
        );
      }
    });

    test('copyWith(name:) 호출 시 원본 인스턴스의 name은 변경되지 않음', () {
      // Validates: Requirements 2.2
      final original = _makeProfile(name: '원본이름');
      original.copyWith(name: '새이름');
      expect(original.name, equals('원본이름'));
    });
  });

  // ─────────────────────────────────────────────
  // copyWith — 다른 필드 업데이트 검증
  // ─────────────────────────────────────────────
  group('copyWith — 다른 필드 업데이트 검증', () {
    test('copyWith(interests:) 후 interests가 올바르게 업데이트됨', () {
      final original = _makeProfile(interests: ['독서']);
      final newInterests = ['여행', '요리', '음악'];
      final updated = original.copyWith(interests: newInterests);

      expect(updated.interests, equals(newInterests));
      // 나머지 필드는 유지
      expect(updated.name, equals(original.name));
      expect(updated.ageRange, equals(original.ageRange));
      expect(updated.gender, equals(original.gender));
      expect(updated.profileImageUrl, equals(original.profileImageUrl));
      expect(updated.rating, equals(original.rating));
    });

    test('copyWith(ageRange:) 후 ageRange가 올바르게 업데이트됨', () {
      final original = _makeProfile(ageRange: '20대');
      final updated = original.copyWith(ageRange: '30대');

      expect(updated.ageRange, equals('30대'));
      expect(updated.name, equals(original.name));
      expect(updated.interests, equals(original.interests));
      expect(updated.gender, equals(original.gender));
    });

    test('copyWith(gender:) 후 gender가 올바르게 업데이트됨', () {
      final original = _makeProfile(gender: '남성');
      final updated = original.copyWith(gender: '여성');

      expect(updated.gender, equals('여성'));
      expect(updated.name, equals(original.name));
      expect(updated.interests, equals(original.interests));
      expect(updated.ageRange, equals(original.ageRange));
    });

    test('copyWith(profileImageUrl:) 후 profileImageUrl이 올바르게 업데이트됨', () {
      final original = _makeProfile(profileImageUrl: 'https://old.com/img.jpg');
      final updated = original.copyWith(profileImageUrl: 'https://new.com/img.jpg');

      expect(updated.profileImageUrl, equals('https://new.com/img.jpg'));
      expect(updated.name, equals(original.name));
    });

    test('인자 없이 copyWith 호출 시 모든 필드가 원본과 동일함', () {
      final original = _makeProfile();
      final copy = original.copyWith();

      expect(copy.name, equals(original.name));
      expect(copy.profileImageUrl, equals(original.profileImageUrl));
      expect(copy.interests, equals(original.interests));
      expect(copy.ageRange, equals(original.ageRange));
      expect(copy.gender, equals(original.gender));
      expect(copy.rating, equals(original.rating));
    });

    test('rating은 copyWith로 변경되지 않음 (항상 원본 유지)', () {
      final original = _makeProfile(rating: 4.8);
      final updated = original.copyWith(name: '새이름');

      expect(updated.rating, equals(4.8));
    });
  });

  // ─────────────────────────────────────────────
  // 속성 1: TimeSlot 직렬화 라운드트립 (Property-Based Test)
  // ─────────────────────────────────────────────
  // Feature: profile-tag-system, Property 1: TimeSlot 직렬화 라운드트립
  // Validates: Requirements 1.3, 4.8
  Glados2(any.int, any.int).test(
    'TimeSlot serialization round trip',
    (weekday, hourIndex) {
      final slot = TimeSlot(
        weekday: weekday.abs() % 7,
        hourIndex: hourIndex.abs() % 24,
      );
      expect(
        TimeSlot.fromSerializedString(slot.toSerializedString()),
        equals(slot),
      );
    },
  );

  // ─────────────────────────────────────────────
  // 속성 2: LocationModel 직렬화 라운드트립 (Property-Based Test)
  // ─────────────────────────────────────────────
  // Validates: Requirements 1.2
  Glados2(any.letters, any.letters).test(
    'LocationModel serialization round trip',
    (province, district) {
      final model = LocationModel(province: province, district: district);
      final roundTripped = LocationModel.fromJson(model.toJson());
      expect(roundTripped, equals(model));
    },
  );
}
