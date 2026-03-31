// test/core/models/tag_colors_test.dart
// Feature: profile-tag-system, Property 8: 태그 색상 완전성
// Validates: Requirements 6.1, 6.5

import 'package:test/test.dart';
import 'package:front/core/models/tag_colors.dart';
import 'package:front/features/home/viewmodels/home_view_model.dart';

void main() {
  // Feature: profile-tag-system, Property 8: 태그 색상 완전성
  test('모든 TagType 값에 대해 kTagColors에 색상이 정의되어 있음', () {
    for (final type in TagType.values) {
      expect(
        kTagColors[type],
        isNotNull,
        reason: 'TagType.$type 에 대한 색상이 kTagColors에 정의되어 있어야 합니다',
      );
    }
  });
}
