//lib/core/models/user_profile.dart

import 'enums.dart';

class LocationModel {
  final String province;
  final String district;

  const LocationModel({required this.province, required this.district});

  Map<String, dynamic> toJson() => {'province': province, 'district': district};

  factory LocationModel.fromJson(Map<String, dynamic> json) => LocationModel(
    province: json['province'] as String,
    district: json['district'] as String,
  );

  @override
  bool operator ==(Object other) =>
      other is LocationModel && other.province == province && other.district == district;

  @override
  int get hashCode => Object.hash(province, district);

  String get displayLabel => district.isEmpty ? province : '$province $district';
}

class TimeSlot {
  final int weekday;   // 0=월, 1=화, ..., 6=일
  final int hourIndex; // 0~23

  const TimeSlot({required this.weekday, required this.hourIndex});

  static const List<String> _weekdayLabels = [
    'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'
  ];

  String toSerializedString() =>
      '${_weekdayLabels[weekday]}-${hourIndex.toString().padLeft(2, '0')}';

  factory TimeSlot.fromSerializedString(String s) {
    final parts = s.split('-');
    final weekday = _weekdayLabels.indexOf(parts[0]);
    final hourIndex = int.parse(parts[1]);
    return TimeSlot(weekday: weekday, hourIndex: hourIndex);
  }

  String get displayLabel =>
      '${_weekdayLabels[weekday]} ${hourIndex.toString().padLeft(2, '0')}:00';

  @override
  bool operator ==(Object other) =>
      other is TimeSlot && other.weekday == weekday && other.hourIndex == hourIndex;

  @override
  int get hashCode => Object.hash(weekday, hourIndex);
}

class UserProfile {
  // --- Backend DB Mapped Fields ---
  final int id;
  final String email;
  final String name;
  final int? birthYear;
  final GenderType? gender;
  final String region;
  final String profileImageUrl;
  final int reputationScore;
  final int onboardingStep;
  final bool isProfileCompleted;

  // --- UI/Mock Specific Fields (Kept for compatibility) ---
  final List<LocationModel> locations;
  final List<TimeSlot> availableTimes;
  final List<String> interests;
  final String? ageRange;
  final double rating;

  UserProfile({
    required this.id,
    required this.email,
    required this.name,
    this.birthYear,
    this.gender,
    required this.region,
    required this.profileImageUrl,
    this.reputationScore = 0,
    this.onboardingStep = 1,
    this.isProfileCompleted = false,
    
    // UI Defaults
    this.locations = const [],
    this.availableTimes = const [],
    this.interests = const [],
    this.ageRange,
    this.rating = 0.0,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int? ?? 0,
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '알 수 없음',
      birthYear: json['birth_year'] as int?,
      gender: json['gender'] != null ? GenderType.fromString(json['gender'] as String) : null,
      region: json['region'] as String? ?? '알 수 없음',
      profileImageUrl: json['profile_image_url'] as String? ?? '',
      reputationScore: json['reputation_score'] as int? ?? 0,
      onboardingStep: json['onboarding_step'] as int? ?? 1,
      isProfileCompleted: json['is_profile_completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'birth_year': birthYear,
      'gender': gender?.value,
      'region': region,
      'profile_image_url': profileImageUrl,
      'reputation_score': reputationScore,
      'onboarding_step': onboardingStep,
      'is_profile_completed': isProfileCompleted,
    };
  }

  /// 출생연도로 나이대 문자열 계산 (예: 20대 초반 / 20대 후반)
  /// 출생연도로 나이대 문자열 계산 (예: 20대 초반 / 20대 후반)
  String get ageRangeLabel {
    if (birthYear == null) return ageRange ?? '';
    final age = DateTime.now().year - birthYear!;
    if (age < 10) return '10대 미만';
    if (age >= 100) return '100세 이상';
    final decade = (age ~/ 10) * 10;
    final half = (age % 10) < 5 ? '초반' : '후반';
    if (decade >= 60) return '60대 이상';
    return '$decade대 $half';
  }

  static const _unset = Object();
  static const unset = _unset; // public alias for MockApiService

  UserProfile copyWith({
    int? id,
    String? email,
    String? name,
    Object? birthYear = _unset,
    Object? gender = _unset,
    String? region,
    String? profileImageUrl,
    int? reputationScore,
    int? onboardingStep,
    bool? isProfileCompleted,
    List<LocationModel>? locations,
    List<TimeSlot>? availableTimes,
    List<String>? interests,
    Object? ageRange = _unset,
    double? rating,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      birthYear: identical(birthYear, _unset) ? this.birthYear : birthYear as int?,
      gender: identical(gender, _unset) ? this.gender : gender as GenderType?,
      region: region ?? this.region,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      reputationScore: reputationScore ?? this.reputationScore,
      onboardingStep: onboardingStep ?? this.onboardingStep,
      isProfileCompleted: isProfileCompleted ?? this.isProfileCompleted,
      locations: locations ?? this.locations,
      availableTimes: availableTimes ?? this.availableTimes,
      interests: interests ?? this.interests,
      ageRange: identical(ageRange, _unset) ? this.ageRange : ageRange as String?,
      rating: rating ?? this.rating,
    );
  }
}
