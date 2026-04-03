// lib/features/evaluation/models/evaluation.dart

enum PositiveTag {
  punctual,
  respectful,
  friendly,
  communicative,
  reliable,
}

extension PositiveTagExtension on PositiveTag {
  String get label {
    switch (this) {
      case PositiveTag.punctual:
        return '시간 약속을 잘 지켜요';
      case PositiveTag.respectful:
        return '매너가 좋고 배려심이 있어요';
      case PositiveTag.friendly:
        return '친절하고 분위기를 잘 띄워요';
      case PositiveTag.communicative:
        return '소통이 원활해요';
      case PositiveTag.reliable:
        return '책임감이 강해요';
    }
  }
}

enum NegativeTag {
  late,
  rude,
  no_show,
  poor_communication,
  inappropriate_behavior,
}

extension NegativeTagExtension on NegativeTag {
  String get label {
    switch (this) {
      case NegativeTag.late:
        return '시간 약속을 지키지 않아요';
      case NegativeTag.rude:
        return '매너가 부족해요';
      case NegativeTag.no_show:
        return '연락 없이 불참했어요';
      case NegativeTag.poor_communication:
        return '소통이 어려워요';
      case NegativeTag.inappropriate_behavior:
        return '불쾌한 행동을 했어요';
    }
  }
}

class Evaluation {
  final int evaluatorId;
  final int evaluateeId;
  final List<PositiveTag> positiveTags;
  final List<NegativeTag> negativeTags;
  final String? comment;

  Evaluation({
    required this.evaluatorId,
    required this.evaluateeId,
    this.positiveTags = const [],
    this.negativeTags = const [],
    this.comment,
  });

  Map<String, dynamic> toJson() {
    return {
      'evaluator_id': evaluatorId,
      'evaluatee_id': evaluateeId,
      'positive_tags': positiveTags.map((e) => e.name).toList(),
      'negative_tags': negativeTags.map((e) => e.name).toList(),
      'comment': comment,
    };
  }
}
