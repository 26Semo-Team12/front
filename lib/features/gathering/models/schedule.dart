class GatheringSchedule {
  final String id;
  final String location;
  final DateTime dateTime;
  bool? isAttending; // null: 미정, true: 참석, false: 불참

  GatheringSchedule({
    required this.id,
    required this.location,
    required this.dateTime,
    this.isAttending,
  });

  GatheringSchedule copyWith({
    String? location,
    DateTime? dateTime,
    bool? isAttending,
  }) {
    // We handle nullable explicitly here by treating a separate param or knowing that we are passing bool explicitly.
    // For simplicity, we just pass the value.
    return GatheringSchedule(
      id: id,
      location: location ?? this.location,
      dateTime: dateTime ?? this.dateTime,
      isAttending: isAttending, // explicitly overrides
    );
  }
}
