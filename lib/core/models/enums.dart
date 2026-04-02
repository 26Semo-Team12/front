// lib/core/models/enums.dart

/// 성별 구분 (MALE, FEMALE, OTHER, PRIVATE)
enum GenderType {
  male('MALE'),
  female('FEMALE'),
  other('OTHER'),
  private('PRIVATE');

  final String value;
  const GenderType(this.value);

  factory GenderType.fromString(String val) {
    return GenderType.values.firstWhere(
      (e) => e.value == val.toUpperCase(),
      orElse: () => GenderType.private,
    );
  }

  String get displayName {
    switch (this) {
      case GenderType.male:
        return '남성';
      case GenderType.female:
        return '여성';
      case GenderType.other:
        return '기타';
      case GenderType.private:
        return '비공개';
    }
  }
}
