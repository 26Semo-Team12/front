//lib/core/models/user_profile.dart

class UserProfile {
  final String name;
  final String profileImageUrl;
  final List<String> interests;
  final String ageRange;
  final String gender;
  final double rating;

  UserProfile({
    required this.name,
    required this.profileImageUrl,
    required this.interests,
    required this.ageRange,
    required this.gender,
    required this.rating,
  });
}
