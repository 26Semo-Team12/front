// lib/features/home/models/invitation.dart

enum InvitationType { newInvitation, longTerm, expired }

/// 서버 message에서 "이번 모임은 ... 준비했어요." 시간 안내 문구를 제거
String _stripTimeGuide(String msg) {
  // 패턴: "이번 모임은 ... 준비했어요." (줄바꿈 포함)
  final cleaned = msg.replaceAll(RegExp(r'\s*이번 모임은[^.]*준비했어요\.\s*'), '').trim();
  return cleaned.isNotEmpty ? cleaned : msg.trim();
}

class Invitation {
  final String id;
  final int? invitationId;
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
    this.invitationId,
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

    // invitationId: 서버의 초대장 고유 ID (respond API에 사용)
    final rawInvId = json['id'];
    final invitationId = rawInvId is int ? rawInvId : int.tryParse(rawInvId?.toString() ?? '');

    // message: 초대 메시지 (카드에 표시) - 시간 안내 문구 제거
    final rawMessage = json['message']?.toString() ?? '';
    final invMessage = _stripTimeGuide(rawMessage);
    // title: gathering 제목 (상세 화면에 표시)
    final gatheringTitle = gathering?['title']?.toString() ?? '새로운 초대';

    return Invitation(
      id: id,
      invitationId: invitationId,
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
    InvitationType? type,
  }) {
    return Invitation(
      id: id,
      invitationId: invitationId,
      type: type ?? this.type,
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
