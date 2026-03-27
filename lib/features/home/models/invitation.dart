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
}
