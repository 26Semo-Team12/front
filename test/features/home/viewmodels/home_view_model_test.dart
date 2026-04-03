// test/features/home/viewmodels/home_view_model_test.dart
// Feature: profile-tag-system, Property 3: 지역 태그 중복 불허
// Feature: profile-tag-system, Property 4: 지역 태그 최대 3개 제한

import 'dart:math';
import 'package:glados/glados.dart';
import 'package:test/test.dart';
import 'package:front/core/models/user_profile.dart';
import 'package:front/core/services/mock_api_service.dart';
import 'package:front/features/home/viewmodels/home_view_model.dart';
import 'package:front/core/models/enums.dart';
import 'package:front/features/home/models/invitation.dart';
import 'package:front/features/auth/services/auth_service.dart';
import 'package:front/features/gathering/services/invite_service.dart';

// ─────────────────────────────────────────────
// 헬퍼 함수
// ─────────────────────────────────────────────

/// 비어있지 않은 임의의 문자열 생성
String _randomNonEmptyString(Random rng, {int maxLength = 20}) {
  const chars = 'abcdefghijklmnopqrstuvwxyz가나다라마바사아자차카타파하';
  final length = rng.nextInt(maxLength) + 1;
  return List.generate(length, (_) => chars[rng.nextInt(chars.length)]).join();
}

/// 공백 문자로만 구성된 임의의 문자열 생성 (1~10개 공백)
String _randomBlankString(Random rng) {
  final length = rng.nextInt(10) + 1;
  return ' ' * length;
}

/// 임의의 태그 목록 생성 (1~6개, 비어있지 않음)
List<String> _randomTagList(Random rng, {int minCount = 1}) {
  final count = rng.nextInt(6) + minCount;
  return List.generate(count, (_) => _randomNonEmptyString(rng, maxLength: 10));
}

/// 임의의 TagType 선택
TagType _randomTagType(Random rng) {
  final values = TagType.values;
  return values[rng.nextInt(values.length)];
}

/// 임의의 InvitationType 선택
InvitationType _randomInvitationType(Random rng) {
  final values = InvitationType.values;
  return values[rng.nextInt(values.length)];
}

/// MockApiService를 초기화하고 HomeViewModel을 생성 후 init() 호출
Future<HomeViewModel> _createViewModel(MockApiService service) async {
  final vm = HomeViewModel(AuthService(), InviteService());
  await vm.init();
  return vm;
}

// ─────────────────────────────────────────────
// 테스트
// ─────────────────────────────────────────────

void main() {
  final random = Random(42);

  // ─────────────────────────────────────────────
  // 속성 1: 태그 삭제 후 목록에서 제거됨 (태스크 4.2)
  // Feature: home-screen-interactions, Property 1: 태그 삭제 후 목록에서 제거됨
  // ─────────────────────────────────────────────
  group('Property 1: 태그 삭제 후 목록에서 제거됨', () {
    test('임의의 interest 태그 목록에서 임의의 태그 삭제 후 해당 값 부재 (100회 반복)', () async {
      // Validates: Requirements 3.2
      for (int i = 0; i < 100; i++) {
        final service = MockApiService();
        final tags = _randomTagList(random, minCount: 1);
        await service.patchMe(interests: tags);

        final vm = await _createViewModel(service);
        final tagToRemove = tags[random.nextInt(tags.length)];

        vm.removeTag(tagToRemove, TagType.interest);

        expect(
          vm.currentUser!.interests.contains(tagToRemove),
          isFalse,
          reason: 'iteration=$i: removeTag("$tagToRemove", interest) 후 interests에 해당 값이 없어야 함',
        );

        vm.dispose();
      }
    });

    test('ageRange 태그 삭제 후 null로 변경됨 (100회 반복)', () async {
      // Validates: Requirements 3.2
      for (int i = 0; i < 100; i++) {
        final service = MockApiService();
        final ageRange = _randomNonEmptyString(random, maxLength: 5);
        await service.patchMe(ageRange: ageRange);

        final vm = await _createViewModel(service);

        vm.removeTag(ageRange, TagType.ageRange);

        expect(
          vm.currentUser!.ageRange,
          isNull,
          reason: 'iteration=$i: removeTag(ageRange) 후 ageRange가 null이어야 함',
        );

        vm.dispose();
      }
    });

    test('gender 태그 삭제 후 null로 변경됨 (100회 반복)', () async {
      // Validates: Requirements 3.2
      for (int i = 0; i < 100; i++) {
        final service = MockApiService();
        final gender = GenderType.male;
        await service.patchMe(gender: gender);

        final vm = await _createViewModel(service);

        vm.removeTag(gender.displayName, TagType.gender);

        expect(
          vm.currentUser!.gender,
          isNull,
          reason: 'iteration=$i: removeTag(gender) 후 gender가 null이어야 함',
        );

        vm.dispose();
      }
    });
  });

  // ─────────────────────────────────────────────
  // 속성 2: 태그 추가 후 목록에 포함됨 (태스크 4.3)
  // Feature: home-screen-interactions, Property 2: 태그 추가 후 목록에 포함됨
  // ─────────────────────────────────────────────
  group('Property 2: 태그 추가 후 목록에 포함됨', () {
    test('임의의 유효 interest 태그 추가 후 interests에 포함됨 (100회 반복)', () async {
      // Validates: Requirements 4.2
      for (int i = 0; i < 100; i++) {
        final service = MockApiService();
        final vm = await _createViewModel(service);
        final newTag = _randomNonEmptyString(random, maxLength: 10);

        await vm.addTag(newTag, TagType.interest);

        expect(
          vm.currentUser!.interests.contains(newTag.trim()),
          isTrue,
          reason: 'iteration=$i: addTag("$newTag", interest) 후 interests에 포함되어야 함',
        );

        vm.dispose();
      }
    });

    test('임의의 유효 ageRange 태그 추가 후 ageRange에 반영됨 (100회 반복)', () async {
      // Validates: Requirements 4.2
      for (int i = 0; i < 100; i++) {
        final service = MockApiService();
        final vm = await _createViewModel(service);
        final newAgeRange = _randomNonEmptyString(random, maxLength: 5);

        await vm.addTag(newAgeRange, TagType.ageRange);

        expect(
          vm.currentUser!.ageRange,
          equals(newAgeRange.trim()),
          reason: 'iteration=$i: addTag("$newAgeRange", ageRange) 후 ageRange가 일치해야 함',
        );

        vm.dispose();
      }
    });

    test('임의의 유효 gender 태그 추가 후 gender에 반영됨 (100회 반복)', () async {
      // Validates: Requirements 4.2
      for (int i = 0; i < 100; i++) {
        final service = MockApiService();
        final vm = await _createViewModel(service);
        final newGender = GenderType.female;

        await vm.addTag(newGender.displayName, TagType.gender);

        expect(
          vm.currentUser!.gender,
          equals(newGender),
          reason: 'iteration=$i: addTag("${newGender.displayName}", gender) 후 gender가 일치해야 함',
        );

        vm.dispose();
      }
    });
  });

  // ─────────────────────────────────────────────
  // 속성 3: 빈 값 입력은 거부됨 (태스크 4.4)
  // Feature: home-screen-interactions, Property 3: 빈 값 입력은 거부됨
  // ─────────────────────────────────────────────
  group('Property 3: 빈 값 입력은 거부됨', () {
    test('공백 문자열로 addTag 시도 시 거부되고 상태 불변 (100회 반복)', () async {
      // Validates: Requirements 4.3
      for (int i = 0; i < 100; i++) {
        final service = MockApiService();
        final vm = await _createViewModel(service);
        final blankValue = _randomBlankString(random);
        final tagType = _randomTagType(random);

        final interestsBefore = List<String>.from(vm.currentUser!.interests);
        final ageRangeBefore = vm.currentUser!.ageRange;
        final genderBefore = vm.currentUser!.gender;

        await vm.addTag(blankValue, tagType);

        expect(
          vm.currentUser!.interests,
          equals(interestsBefore),
          reason: 'iteration=$i: 공백 addTag 후 interests가 변경되지 않아야 함',
        );
        expect(
          vm.currentUser!.ageRange,
          equals(ageRangeBefore),
          reason: 'iteration=$i: 공백 addTag 후 ageRange가 변경되지 않아야 함',
        );
        expect(
          vm.currentUser!.gender,
          equals(genderBefore),
          reason: 'iteration=$i: 공백 addTag 후 gender가 변경되지 않아야 함',
        );

        vm.dispose();
      }
    });

    test('공백 문자열로 updateProfile(name) 시도 시 거부되고 이름 불변 (100회 반복)', () async {
      // Validates: Requirements 2.4
      for (int i = 0; i < 100; i++) {
        final service = MockApiService();
        final vm = await _createViewModel(service);
        final blankName = _randomBlankString(random);
        final nameBefore = vm.currentUser!.name;

        await vm.updateProfile(name: blankName);

        expect(
          vm.currentUser!.name,
          equals(nameBefore),
          reason: 'iteration=$i: 공백 이름으로 updateProfile 후 name이 변경되지 않아야 함',
        );

        vm.dispose();
      }
    });
  });

  // ─────────────────────────────────────────────
  // 속성 6/7: 필터 속성 테스트 (태스크 4.5)
  // Feature: home-screen-interactions, Property 6/7
  // ─────────────────────────────────────────────
  group('Property 6: 필터 적용 시 해당 타입만 반환됨', () {
    test('임의의 Invitation 목록에 필터 적용 시 결과가 해당 타입만 포함 (100회 반복)', () async {
      // Validates: Requirements 6.5
      for (int i = 0; i < 100; i++) {
        final service = MockApiService();
        final vm = await _createViewModel(service);
        final filterType = _randomInvitationType(random);

        // _activeFilters를 명시적으로 클리어하고 타겟만 추가
        for (var t in InvitationType.values) {
          if (vm.activeFilters.contains(t)) {
             vm.toggleFilter(t);
          }
        }
        vm.toggleFilter(filterType);

        final filtered = vm.filteredInvitations;
        for (final inv in filtered) {
          expect(
            inv.type,
            equals(filterType),
            reason: 'iteration=$i: 필터($filterType) 적용 후 모든 항목의 type이 $filterType이어야 함',
          );
        }

        vm.dispose();
      }
    });
  });

  group('Property 7: 필터 토글 라운드 트립', () {
    test('필터 활성화 후 동일 필터 재탭 시 전체 목록 복원 (100회 반복)', () async {
      // Validates: Requirements 6.6
      for (int i = 0; i < 100; i++) {
        final service = MockApiService();
        final vm = await _createViewModel(service);
        final filterType = _randomInvitationType(random);

        final allBefore = vm.filteredInvitations;

        // 필터 활성화
        vm.toggleFilter(filterType);
        // 동일 필터 재탭 → 전체 복원
        vm.toggleFilter(filterType);

        final allAfter = vm.filteredInvitations;

        expect(
          allAfter.length,
          equals(allBefore.length),
          reason: 'iteration=$i: 필터 토글 라운드 트립 후 전체 목록 길이가 복원되어야 함',
        );
        expect(
          allAfter.map((e) => e.id).toList(),
          equals(allBefore.map((e) => e.id).toList()),
          reason: 'iteration=$i: 필터 토글 라운드 트립 후 전체 목록 내용이 복원되어야 함',
        );

        vm.dispose();
      }
    });

    test('초기 상태에서 filteredInvitations는 활성화된 필터에 해당하는 목록 반환', () async {
      // Validates: Requirements 6.4
      final service = MockApiService();
      final vm = await _createViewModel(service);

      final allInvitations = vm.filteredInvitations;
      final allFromService = await service.getInvitations();
      final expectedCount = allFromService.where((i) => vm.activeFilters.contains(i.type)).length;

      expect(
        allInvitations.length,
        equals(expectedCount),
        reason: '초기 상태의 필터 설정에 따른 길이가 반환되어야 함',
      );

      vm.dispose();
    });
  });

  // ─────────────────────────────────────────────
  // Property 3: 지역 태그 중복 불허 (태스크 4.3)
  // Feature: profile-tag-system, Property 3: 지역 태그 중복 불허
  // **Validates: Requirements 3.8, 8.4**
  // ─────────────────────────────────────────────
  Glados2(any.letters, any.letters).test(
    'addLocation rejects duplicates',
    (province, district) async {
      final vm = HomeViewModel(AuthService(), InviteService());
      await vm.init();
      final location = LocationModel(province: province, district: district);
      await vm.addLocation(location);
      final lengthAfterFirst = vm.currentUser!.locations.length;
      await vm.addLocation(location); // 동일 값 재추가
      expect(vm.currentUser!.locations.length, equals(lengthAfterFirst));
    },
  );

  // ─────────────────────────────────────────────
  // Property 5: 시간 태그 전체 교체 (태스크 4.6)
  // Feature: profile-tag-system, Property 5: 시간 태그 전체 교체
  // **Validates: Requirements 4.4, 8.2, 8.5**
  // ─────────────────────────────────────────────

  // Feature: profile-tag-system, Property 5: 시간 태그 전체 교체
  // Validates: Requirements 4.4, 8.2, 8.5
  test('updateAvailableTimes replaces availableTimes completely', () async {
    final vm = HomeViewModel(AuthService(), InviteService());
    await vm.init();
    final newSlots = [
      TimeSlot(weekday: 1, hourIndex: 10),
      TimeSlot(weekday: 3, hourIndex: 15),
      TimeSlot(weekday: 5, hourIndex: 20),
    ];
    await vm.updateAvailableTimes(newSlots);
    expect(vm.currentUser!.availableTimes, equals(newSlots));
  });

  // Feature: profile-tag-system, Property 5: 시간 태그 전체 교체 (PBT)
  Glados2(any.int, any.int).test(
    'updateAvailableTimes replaces with arbitrary slots',
    (weekday, hourIndex) async {
      final vm = HomeViewModel(AuthService(), InviteService());
      await vm.init();
      final slot = TimeSlot(weekday: weekday.abs() % 7, hourIndex: hourIndex.abs() % 24);
      await vm.updateAvailableTimes([slot]);
      expect(vm.currentUser!.availableTimes, equals([slot]));
    },
  );

  // ─────────────────────────────────────────────
  // Property 6: 태그 삭제 후 목록에서 제거 (태스크 4.8)
  // Feature: profile-tag-system, Property 6: 태그 삭제 후 목록에서 제거
  // **Validates: Requirements 2.4, 5.5, 8.6, 8.7**
  // ─────────────────────────────────────────────
  group('Property 6: 태그 삭제 후 목록에서 제거', () {
    test('removeTag(location) 후 해당 location이 목록에서 제거됨', () async {
      final vm = HomeViewModel(AuthService(), InviteService());
      await vm.init();
      // MockApiService starts with 1 location: LocationModel(province: '로렘시', district: '입숨구')
      final existingLabel = vm.currentUser!.locations.first.displayLabel;
      vm.removeTag(existingLabel, TagType.location);
      expect(
        vm.currentUser!.locations.any((loc) => loc.displayLabel == existingLabel),
        isFalse,
      );
    });

    test('removeTag(time) 후 해당 TimeSlot이 목록에서 제거됨', () async {
      final vm = HomeViewModel(AuthService(), InviteService());
      await vm.init();
      // MockApiService starts with 3 time slots
      final existingLabel = vm.currentUser!.availableTimes.first.displayLabel;
      vm.removeTag(existingLabel, TagType.time);
      expect(
        vm.currentUser!.availableTimes.any((slot) => slot.displayLabel == existingLabel),
        isFalse,
      );
    });

    test('removeTag(interest) 후 해당 interest가 목록에서 제거됨', () async {
      final vm = HomeViewModel(AuthService(), InviteService());
      await vm.init();
      final existingInterest = vm.currentUser!.interests.first;
      vm.removeTag(existingInterest, TagType.interest);
      expect(vm.currentUser!.interests.contains(existingInterest), isFalse);
    });

    test('removeTag(ageRange) 후 ageRange가 null이 됨', () async {
      final vm = HomeViewModel(AuthService(), InviteService());
      await vm.init();
      vm.removeTag('20대', TagType.ageRange);
      expect(vm.currentUser!.ageRange, isNull);
    });

    test('removeTag(gender) 후 gender가 null이 됨', () async {
      final vm = HomeViewModel(AuthService(), InviteService());
      await vm.init();
      vm.removeTag('남성', TagType.gender);
      expect(vm.currentUser!.gender, isNull);
    });
  });

  // ─────────────────────────────────────────────
  // Property 7: 공백 관심사 추가 거부 (태스크 4.9)
  // Feature: profile-tag-system, Property 7: 공백 관심사 추가 거부
  // **Validates: Requirements 5.6**
  // ─────────────────────────────────────────────
  test('addTag rejects whitespace-only interest strings (manual)', () async {
    final whitespaceStrings = [' ', '  ', '\t', '\n', '   \t\n  '];
    for (final ws in whitespaceStrings) {
      final vm = HomeViewModel(AuthService(), InviteService());
      await vm.init();
      final interestsBefore = List<String>.from(vm.currentUser!.interests);
      await vm.addTag(ws, TagType.interest);
      expect(vm.currentUser!.interests, equals(interestsBefore),
          reason: 'addTag("$ws", interest) should be rejected');
      vm.dispose();
    }
  });

  // ─────────────────────────────────────────────
  // Property 4: 지역 태그 최대 3개 제한 (태스크 4.4)
  // Feature: profile-tag-system, Property 4: 지역 태그 최대 3개 제한
  // **Validates: Requirements 3.6, 8.4**
  // ─────────────────────────────────────────────
  test('locations never exceed 3', () async {
    final vm = HomeViewModel(AuthService(), InviteService());
    await vm.init();
    // MockApiService starts with 1 location. Add 4 different ones — total capped at 3.
    final locations = [
      LocationModel(province: '서울', district: '강남구'),
      LocationModel(province: '경기', district: '수원시'),
      LocationModel(province: '부산', district: '해운대구'),
      LocationModel(province: '인천', district: '남동구'),
    ];
    for (final loc in locations) {
      await vm.addLocation(loc);
    }
    expect(vm.currentUser!.locations.length, lessThanOrEqualTo(3));
  });
}
