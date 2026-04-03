import 'package:flutter/material.dart';
import '../../../core/models/user_profile.dart';
import '../models/evaluation.dart';
import '../services/evaluation_service.dart';

class EvaluationViewModel extends ChangeNotifier {
  final int gatheringId;
  final List<UserProfile> participants;
  final int currentUserId;

  final EvaluationService _evaluationService = EvaluationService();

  List<UserProfile> _evaluatees = [];
  List<UserProfile> get evaluatees => _evaluatees;

  int? _activeEvaluateeId;
  int? get activeEvaluateeId => _activeEvaluateeId;

  // Track the state for each evaluatee
  final Map<int, List<PositiveTag>> _positiveTags = {};
  final Map<int, List<NegativeTag>> _negativeTags = {};
  final Map<int, String> _comments = {};

  final Set<int> _completedEvaluationIds = {};
  Set<int> get completedEvaluationIds => _completedEvaluationIds;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  EvaluationViewModel({
    required this.gatheringId,
    required this.participants,
    required this.currentUserId,
  }) {
    _evaluatees = participants.where((p) => p.id != currentUserId).toList();
    if (_evaluatees.isNotEmpty) {
      _activeEvaluateeId = _evaluatees.first.id;
    }
    for (var evaluatee in _evaluatees) {
      _positiveTags[evaluatee.id] = [];
      _negativeTags[evaluatee.id] = [];
      _comments[evaluatee.id] = '';
    }
  }

  void setActiveEvaluatee(int id) {
    if (_activeEvaluateeId != id) {
      _activeEvaluateeId = id;
      notifyListeners();
    }
  }

  List<PositiveTag> getActivePositiveTags() => _positiveTags[_activeEvaluateeId] ?? [];
  List<NegativeTag> getActiveNegativeTags() => _negativeTags[_activeEvaluateeId] ?? [];

  void togglePositiveTag(PositiveTag tag) {
    if (_activeEvaluateeId == null) return;
    final tags = _positiveTags[_activeEvaluateeId]!;
    if (tags.contains(tag)) {
      tags.remove(tag);
    } else {
      if (tags.length < 3) {
        tags.add(tag);
      }
    }
    notifyListeners();
  }

  void toggleNegativeTag(NegativeTag tag) {
    if (_activeEvaluateeId == null) return;
    final tags = _negativeTags[_activeEvaluateeId]!;
    if (tags.contains(tag)) {
      tags.remove(tag);
    } else {
      if (tags.length < 3) {
        tags.add(tag);
      }
    }
    notifyListeners();
  }

  void updateComment(String comment) {
    if (_activeEvaluateeId == null) return;
    _comments[_activeEvaluateeId!] = comment;
    notifyListeners();
  }

  bool get canSubmitActive {
    if (_activeEvaluateeId == null) return false;
    final posTags = _positiveTags[_activeEvaluateeId]!;
    final negTags = _negativeTags[_activeEvaluateeId]!;
    return posTags.isNotEmpty || negTags.isNotEmpty;
  }
  
  bool get allEvaluationsCompleted => _completedEvaluationIds.length == _evaluatees.length;

  Future<void> submitActiveEvaluation(VoidCallback onAllCompleted) async {
    if (_activeEvaluateeId == null) return;
    
    _isSubmitting = true;
    notifyListeners();
    
    try {
      await _evaluationService.submitEvaluation(
        gatheringId: gatheringId,
        evaluateeId: _activeEvaluateeId!,
        positiveTags: _positiveTags[_activeEvaluateeId]!,
        negativeTags: _negativeTags[_activeEvaluateeId]!,
        comment: _comments[_activeEvaluateeId],
      );
      
      _completedEvaluationIds.add(_activeEvaluateeId!);
      
      if (allEvaluationsCompleted) {
        onAllCompleted();
      } else {
        // Find next uncompleted evaluatee
        final nextEvaluatee = _evaluatees.firstWhere(
          (p) => !_completedEvaluationIds.contains(p.id),
        );
        _activeEvaluateeId = nextEvaluatee.id;
      }
    } catch (e) {
      debugPrint('Failed to submit evaluation: $e');
      // For now, still mark as completed in UI if it fails? 
      // Or show error snackbar. Let's just catch and keep state for now.
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
