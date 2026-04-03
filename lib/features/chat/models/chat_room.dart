// lib/features/chat/models/chat_room.dart

class ChatRoom {
  final int id;
  final String roomType; // GATHERING | DIRECT
  final int? gatheringId;
  final int? user1Id;
  final int? user2Id;
  final String? gatheringTitle;
  final String? gatheringRegion;
  final DateTime? meetTime;
  final int? memberCount;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final DateTime createdAt;

  ChatRoom({
    required this.id,
    required this.roomType,
    this.gatheringId,
    this.user1Id,
    this.user2Id,
    this.gatheringTitle,
    this.gatheringRegion,
    this.meetTime,
    this.memberCount,
    this.lastMessageAt,
    this.unreadCount = 0,
    required this.createdAt,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] as int,
      roomType: json['roomType'] as String? ?? 'GATHERING',
      gatheringId: json['gatheringId'] as int?,
      user1Id: json['user1Id'] as int?,
      user2Id: json['user2Id'] as int?,
      gatheringTitle: json['gatheringTitle'] as String?,
      gatheringRegion: json['gatheringRegion'] as String?,
      meetTime: json['meetTime'] != null ? DateTime.parse(json['meetTime'] as String) : null,
      memberCount: json['memberCount'] as int?,
      lastMessageAt: json['lastMessageAt'] != null ? DateTime.parse(json['lastMessageAt'] as String) : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomType': roomType,
      'gatheringId': gatheringId,
      'user1Id': user1Id,
      'user2Id': user2Id,
      'gatheringTitle': gatheringTitle,
      'gatheringRegion': gatheringRegion,
      'meetTime': meetTime?.toIso8601String(),
      'memberCount': memberCount,
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'unreadCount': unreadCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
