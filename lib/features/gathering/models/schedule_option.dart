// lib/features/gathering/models/schedule_option.dart

enum VoteStatus {
  AVAILABLE,
  MAYBE,
  UNAVAILABLE;

  static VoteStatus? fromString(String? val) {
    if (val == 'AVAILABLE') return VoteStatus.AVAILABLE;
    if (val == 'MAYBE') return VoteStatus.MAYBE;
    if (val == 'UNAVAILABLE') return VoteStatus.UNAVAILABLE;
    return null;
  }

  String get value => name;
}

class ScheduleOption {
  final int id;
  final int gatheringId;
  final int proposerUserId;
  final DateTime startAt;
  final int availableCount;
  final int maybeCount;
  final int unavailableCount;
  final VoteStatus? myVote;
  final bool isSelected;

  ScheduleOption({
    required this.id,
    required this.gatheringId,
    required this.proposerUserId,
    required this.startAt,
    required this.availableCount,
    required this.maybeCount,
    required this.unavailableCount,
    this.myVote,
    required this.isSelected,
  });

  factory ScheduleOption.fromJson(Map<String, dynamic> json) {
    return ScheduleOption(
      id: json['id'] as int,
      gatheringId: json['gatheringId'] as int,
      proposerUserId: json['proposerUserId'] as int,
      startAt: DateTime.parse(json['startAt'] as String),
      availableCount: json['availableCount'] as int? ?? 0,
      maybeCount: json['maybeCount'] as int? ?? 0,
      unavailableCount: json['unavailableCount'] as int? ?? 0,
      myVote: VoteStatus.fromString(json['myVote'] as String?),
      isSelected: json['isSelected'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gatheringId': gatheringId,
      'proposerUserId': proposerUserId,
      'startAt': startAt.toIso8601String(),
      'availableCount': availableCount,
      'maybeCount': maybeCount,
      'unavailableCount': unavailableCount,
      'myVote': myVote?.value,
      'isSelected': isSelected,
    };
  }
}
