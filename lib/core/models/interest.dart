// lib/core/models/interest.dart

class Interest {
  final int id;
  final String name;

  const Interest({
    required this.id,
    required this.name,
  });

  factory Interest.fromJson(Map<String, dynamic> json) {
    return Interest(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  // To maintain compatibility with existing simple string usage
  @override
  String toString() => name;
}
