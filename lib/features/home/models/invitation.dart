// lib/features/home/models/invitation.dart

class Invitation {
  final String title;
  final String description;
  final bool isNew;
  final bool isRegular;

  Invitation({
    required this.title,
    required this.description,
    this.isNew = false,
    this.isRegular = false,
  });
}
