// lib/core/models/user_profile.dart

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
      other is LocationModel &&
      other.province == province &&
      other.district == district;

  @override
  int get hashCode => Object.hash(province, district);

  String get displayLabel =>
      district.isEmpty ? province : '$province $district';
}

class TimeSlot {
  final int weekday; // 0=월, 1=화, ..., 6=일
  final int hourIndex; // 0~23

  const TimeSlot({required this.weekday, required this.hourIndex});

  Map<String, dynamic> toJson() => {'weekday': weekday, 'hourIndex': hourIndex};

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    // 서버 형식: {"weekday": "MONDAY", "hour": 19} 또는 로컬 형식: {"weekday": 0, "hourIndex": 19}
    final rawWeekday = json['weekday'];
    int weekday;
    if (rawWeekday is int) {
      weekday = rawWeekday;
    } else if (rawWeekday is String) {
      weekday = _serverWeekdayToIndex(rawWeekday);
    } else {
      weekday = 0;
    }

    final hour = json['hour'] ?? json['hourIndex'];
    final hourIndex = hour is int ? hour : int.tryParse(hour?.toString() ?? '') ?? 0;

    return TimeSlot(weekday: weekday, hourIndex: hourIndex);
  }

  /// 서버 API 형식으로 변환: {"weekday": "MONDAY", "hour": 19}
  Map<String, dynamic> toServerJson() => {
    'weekday': _serverWeekdayNames[weekday],
    'hour': hourIndex,
  };

  /// 서버 응답의 요일 문자열 → int 인덱스
  static int _serverWeekdayToIndex(String name) {
    final idx = _serverWeekdayNames.indexOf(name.toUpperCase());
    return idx >= 0 ? idx : 0;
  }

  static const List<String> _serverWeekdayNames = [
    'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY',
  ];

  static const List<String> _weekdayLabels = [
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
    'SUN',
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
      other is TimeSlot &&
      other.weekday == weekday &&
      other.hourIndex == hourIndex;

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
  final bool isRandomModeEnabled;
  final int? age;
  final String? location;
  final String? preferredSize;
  final List<String> interests;
  final DateTime? createdAt;
  final int reputationScore;
  final int onboardingStep;
  final bool isProfileCompleted;

  // --- UI/Mock Specific Fields (Kept for compatibility) ---
  final List<LocationModel> locations;
  final List<TimeSlot> availableTimes;
  final String? ageRange;
  final double rating;

  UserProfile({
    this.isRandomModeEnabled = false,
    this.age,
    this.location,
    this.preferredSize,
    this.interests = const [],
    this.createdAt,
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
    this.ageRange,
    this.rating = 0.0,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // birthYear: birth_year 또는 birthYear 키 모두 시도
    final rawBirthYear = json['birth_year'] ?? json['birthYear'];
    final parsedBirthYear = rawBirthYear is int
        ? rawBirthYear
        : int.tryParse(rawBirthYear?.toString() ?? '');

    // age로 birthYear 역산 (birth_year가 없을 때)
    final rawAge = json['age'] is int ? json['age'] as int : int.tryParse(json['age']?.toString() ?? '');
    final birthYearFromAge = (parsedBirthYear == null && rawAge != null && rawAge > 0)
        ? DateTime.now().year - rawAge
        : null;
    final finalBirthYear = parsedBirthYear ?? birthYearFromAge;

    // locations: locations 배열 또는 location 문자열로 fallback
    List<LocationModel> parsedLocations = [];
    if (json['locations'] is List && (json['locations'] as List).isNotEmpty) {
      parsedLocations = (json['locations'] as List<dynamic>)
          .map((e) => LocationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      // location 문자열 → LocationModel 변환 (서버는 단순 문자열로 줌)
      final locStr = (json['location'] as String?)?.trim() ?? '';
      if (locStr.isNotEmpty) {
        // "경기도 수원시" 형태면 분리, 아니면 전체를 province로
        final parts = locStr.split(' ');
        if (parts.length >= 2) {
          parsedLocations = [LocationModel(province: parts[0], district: parts.sublist(1).join(' '))];
        } else {
          parsedLocations = [LocationModel(province: locStr, district: '')];
        }
      }
    }

    return UserProfile(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '알 수 없음',
      birthYear: finalBirthYear,
      gender: json['gender'] != null
          ? GenderType.fromString(json['gender'] as String)
          : null,
      region: json['region'] as String? ?? json['location'] as String? ?? '알 수 없음',
      profileImageUrl: json['profile_image_url'] as String? ?? json['profileImageUrl'] as String? ?? '',
      isRandomModeEnabled: json['isRandomModeEnabled'] as bool? ?? false,
      age: rawAge ?? 0,
      location: json['location'] as String?,
      preferredSize: json['preferredSize'] as String? ?? 'any',
      interests:
          (json['interests'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      reputationScore: json['reputation_score'] is int
          ? json['reputation_score'] as int
          : int.tryParse(json['reputation_score']?.toString() ?? '') ?? 0,
      onboardingStep: json['onboarding_step'] is int
          ? json['onboarding_step'] as int
          : int.tryParse(json['onboarding_step']?.toString() ?? '') ?? 1,
      isProfileCompleted: json['is_profile_completed'] as bool? ?? false,
      locations: parsedLocations,
      availableTimes: (json['available_times'] as List<dynamic>?)
          ?.map((e) => TimeSlot.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
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
      'isRandomModeEnabled': isRandomModeEnabled,
      'age': age,
      'location': location,
      'preferredSize': preferredSize,
      'interests': interests,
      'createdAt': createdAt?.toIso8601String(),
      'reputation_score': reputationScore,
      'onboarding_step': onboardingStep,
      'is_profile_completed': isProfileCompleted,
      'locations': locations.map((e) => e.toJson()).toList(),
      'available_times': availableTimes.map((e) => e.toJson()).toList(),
    };
  }

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

  /// 화면에 표시할 연도/나이 문자열
  /// 서버는 age만 주므로 birthYear가 없으면 age로 역산한 연도 표시
  String get displayBirthYear {
    if (birthYear != null) return birthYear.toString();
    if (age != null && age! > 0) return (DateTime.now().year - age!).toString();
    return '연도미상';
  }

  static const _unset = Object();
  static const unset = _unset; // public alias for services to handle null vs unset

  UserProfile copyWith({
    int? id,
    String? email,
    String? name,
    Object? birthYear = _unset,
    Object? gender = _unset,
    String? region,
    String? profileImageUrl,
    bool? isRandomModeEnabled,
    int? age,
    String? location,
    String? preferredSize,
    List<String>? interests,
    DateTime? createdAt,
    int? reputationScore,
    int? onboardingStep,
    bool? isProfileCompleted,
    List<LocationModel>? locations,
    List<TimeSlot>? availableTimes,
    Object? ageRange = _unset,
    double? rating,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      birthYear: identical(birthYear, _unset)
          ? this.birthYear
          : birthYear as int?,
      gender: identical(gender, _unset) ? this.gender : gender as GenderType?,
      region: region ?? this.region,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isRandomModeEnabled: isRandomModeEnabled ?? this.isRandomModeEnabled,
      age: age ?? this.age,
      location: location ?? this.location,
      preferredSize: preferredSize ?? this.preferredSize,
      interests: interests ?? this.interests,
      createdAt: createdAt ?? this.createdAt,
      reputationScore: reputationScore ?? this.reputationScore,
      onboardingStep: onboardingStep ?? this.onboardingStep,
      isProfileCompleted: isProfileCompleted ?? this.isProfileCompleted,
      locations: locations ?? this.locations,
      availableTimes: availableTimes ?? this.availableTimes,
      ageRange: identical(ageRange, _unset)
          ? this.ageRange
          : ageRange as String?,
      rating: rating ?? this.rating,
    );
  }
}
