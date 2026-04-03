// lib/features/home/models/invitation.dart

enum InvitationType { newInvitation, longTerm, expired }

class Invitation {
  final String id;
  final InvitationType type;
  final String title;
  final DateTime dateTime;
  final String location;
  final String? imageUrl;
  final int memberCount;

  Invitation({
    required this.id,
    required this.type,
    required this.title,
    required this.dateTime,
    required this.location,
    this.imageUrl,
    required this.memberCount,
  });

  factory Invitation.fromJson(Map<String, dynamic> json) {
    final gathering = json['gathering'] as Map<String, dynamic>?;
    return Invitation(
      id: json['id'].toString(),
      type: _parseType(json['status']),
      title: gathering?['title'] ?? json['message'] ?? '새로운 초대',
      dateTime: DateTime.parse(gathering?['dateTime'] ?? DateTime.now().toIso8601String()),
      location: gathering?['location'] ?? '장소 미정',
      imageUrl: gathering?['image_url'],
      memberCount: gathering?['memberCount'] ?? 0,
    );
  }

  static InvitationType _parseType(String? status) {
    switch (status?.toUpperCase()) {
      case 'PENDING':
        return InvitationType.newInvitation;
      case 'ACCEPTED':
      case 'REJECTED':
      case 'CANCELLED':
        return InvitationType.expired;
      default:
        return InvitationType.newInvitation;
    }
  }

  Invitation copyWith({
    String? title,
    String? imageUrl,
  }) {
    return Invitation(
      id: id,
      type: type,
      title: title ?? this.title,
      dateTime: dateTime,
      location: location,
      imageUrl: imageUrl ?? this.imageUrl,
      memberCount: memberCount,
    );
  }
}
