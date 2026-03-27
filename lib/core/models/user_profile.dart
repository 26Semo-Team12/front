//lib/core/models/user_profile.dart

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
  final String name;
  final String profileImageUrl;
  final List<LocationModel> locations;
  final List<TimeSlot> availableTimes;
  final List<String> interests;
  final String? ageRange;
  final String? gender;
  final double rating;

  UserProfile({
    required this.name,
    required this.profileImageUrl,
    required this.locations,
    required this.availableTimes,
    required this.interests,
    this.ageRange,
    this.gender,
    required this.rating,
  });

  static const _unset = Object();

  UserProfile copyWith({
    String? name,
    String? profileImageUrl,
    List<LocationModel>? locations,
    List<TimeSlot>? availableTimes,
    List<String>? interests,
    Object? ageRange = _unset,
    Object? gender = _unset,
  }) {
    return UserProfile(
      name: name ?? this.name,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      locations: locations ?? this.locations,
      availableTimes: availableTimes ?? this.availableTimes,
      interests: interests ?? this.interests,
      ageRange: identical(ageRange, _unset) ? this.ageRange : ageRange as String?,
      gender: identical(gender, _unset) ? this.gender : gender as String?,
      rating: rating,
    );
  }
}
