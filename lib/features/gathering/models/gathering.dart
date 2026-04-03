// lib/features/gathering/models/gathering.dart

class Gathering {
  final int id;
  final int? hostUserId;
  final String? hostName;
  final int? placeId;
  final String? placeName;
  final String? placeAddress;
  final String title;
  final String? description;
  final String type; // SMALL | LARGE
  final String region;
  final String status; // RECRUITING | ...
  final String createdByType; // SYSTEM | USER
  final String accessPolicy; // INVITE_ONLY | ...
  final DateTime? meetTime;
  final int maxMembers;
  final int memberCount;
  final List<int> interestIds;
  final String matchingMode; // INTEREST | RANDOM
  final int? targetAgeMin;
  final int? targetAgeMax;
  final String targetGender; // ANY | MALE | FEMALE
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? joinedAt;

  Gathering({
    required this.id,
    this.hostUserId,
    this.hostName,
    this.placeId,
    this.placeName,
    this.placeAddress,
    required this.title,
    this.description,
    required this.type,
    required this.region,
    required this.status,
    required this.createdByType,
    required this.accessPolicy,
    this.meetTime,
    required this.maxMembers,
    required this.memberCount,
    this.interestIds = const [],
    required this.matchingMode,
    this.targetAgeMin,
    this.targetAgeMax,
    required this.targetGender,
    required this.createdAt,
    required this.updatedAt,
    this.joinedAt,
  });

  factory Gathering.fromJson(Map<String, dynamic> json) {
    return Gathering(
      id: json['id'] as int,
      hostUserId: json['hostUserId'] as int?,
      hostName: json['hostName'] as String?,
      placeId: json['placeId'] as int?,
      placeName: json['placeName'] as String?,
      placeAddress: json['placeAddress'] as String?,
      title: json['title'] as String? ?? '무제 모임',
      description: json['description'] as String?,
      type: json['type'] as String? ?? 'SMALL',
      region: json['region'] as String? ?? '',
      status: json['status'] as String? ?? 'RECRUITING',
      createdByType: json['createdByType'] as String? ?? 'SYSTEM',
      accessPolicy: json['accessPolicy'] as String? ?? 'INVITE_ONLY',
      meetTime: json['meetTime'] != null ? DateTime.parse(json['meetTime'] as String) : null,
      maxMembers: json['maxMembers'] as int? ?? 0,
      memberCount: json['memberCount'] as int? ?? 0,
      interestIds: (json['interestIds'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
      matchingMode: json['matchingMode'] as String? ?? 'INTEREST',
      targetAgeMin: json['targetAgeMin'] as int?,
      targetAgeMax: json['targetAgeMax'] as int?,
      targetGender: json['targetGender'] as String? ?? 'ANY',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : DateTime.now(),
      joinedAt: json['joinedAt'] != null ? DateTime.parse(json['joinedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hostUserId': hostUserId,
      'hostName': hostName,
      'placeId': placeId,
      'placeName': placeName,
      'placeAddress': placeAddress,
      'title': title,
      'description': description,
      'type': type,
      'region': region,
      'status': status,
      'createdByType': createdByType,
      'accessPolicy': accessPolicy,
      'meetTime': meetTime?.toIso8601String(),
      'maxMembers': maxMembers,
      'memberCount': memberCount,
      'interestIds': interestIds,
      'matchingMode': matchingMode,
      'targetAgeMin': targetAgeMin,
      'targetAgeMax': targetAgeMax,
      'targetGender': targetGender,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'joinedAt': joinedAt?.toIso8601String(),
    };
  }
}
