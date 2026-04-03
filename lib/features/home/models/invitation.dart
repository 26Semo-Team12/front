// lib/features/home/models/invitation.dart

enum InvitationType { newInvitation, longTerm, expired }

class Invitation {
  final String id;
  final InvitationType type;
  final String title;
  final String message;
  final DateTime dateTime;
  final String location;
  final String? imageUrl;
  final int memberCount;
  final bool isRead;

  Invitation({
    required this.id,
    required this.type,
    required this.title,
    this.message = '',
    required this.dateTime,
    required this.location,
    this.imageUrl,
    required this.memberCount,
    this.isRead = false,
  });

  factory Invitation.fromJson(Map<String, dynamic> json) {
    final gathering = json['gathering'] as Map<String, dynamic>?;

    // meetTime 파싱
    final meetTimeStr = gathering?['meetTime'] ?? json['sentAt'];
    final dateTime = meetTimeStr != null
        ? DateTime.tryParse(meetTimeStr.toString()) ?? DateTime.now()
        : DateTime.now();

    // 모임 타입 결정
    final status = json['status']?.toString() ?? 'PENDING';
    final gatheringStatus = gathering?['status']?.toString() ?? '';
    InvitationType type;
    if (status == 'EXPIRED' || status == 'REJECTED' || status == 'CANCELLED') {
      type = InvitationType.expired;
    } else if (status == 'ACCEPTED' || gatheringStatus == 'ACTIVE') {
      type = InvitationType.longTerm;
    } else {
      type = InvitationType.newInvitation;
    }

    // id 안전 파싱 (String 또는 int 모두 처리)
    final rawId = gathering?['id'] ?? json['gatheringId'] ?? json['id'];
    final id = rawId?.toString() ?? '0';

    // memberCount 안전 파싱
    final rawMemberCount = gathering?['memberCount'];
    final memberCount = rawMemberCount is int
        ? rawMemberCount
        : int.tryParse(rawMemberCount?.toString() ?? '') ?? 0;

    // message: 초대 메시지 (카드에 표시)
    final invMessage = json['message']?.toString() ?? '';
    // title: gathering 제목 (상세 화면에 표시)
    final gatheringTitle = gathering?['title']?.toString() ?? '새로운 초대';

    return Invitation(
      id: id,
      type: type,
      title: gatheringTitle,
      message: invMessage,
      dateTime: dateTime,
      location: gathering?['region']?.toString() ?? '장소 미정',
      imageUrl: gathering?['imageUrl']?.toString(),
      memberCount: memberCount,
    );
  }

  Invitation copyWith({
    String? title,
    String? message,
    String? imageUrl,
    bool? isRead,
  }) {
    return Invitation(
      id: id,
      type: type,
      title: title ?? this.title,
      message: message ?? this.message,
      dateTime: dateTime,
      location: location,
      imageUrl: imageUrl ?? this.imageUrl,
      memberCount: memberCount,
      isRead: isRead ?? this.isRead,
    );
  }
}
