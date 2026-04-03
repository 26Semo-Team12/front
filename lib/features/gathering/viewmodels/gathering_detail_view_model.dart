import 'package:flutter/material.dart';
import '../../home/models/invitation.dart';
import '../models/schedule.dart';

class GatheringDetailViewModel extends ChangeNotifier {
  Invitation _invitation;
  final void Function(String id, String? newTitle, String? newImageUrl) onUpdateGlobalMeta;

  Invitation get invitation => _invitation;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final List<GatheringSchedule> _schedules = [];

  List<GatheringSchedule> get sortedSchedules {
    final list = List<GatheringSchedule>.from(_schedules);
    // Sort by chronological order, earliest first
    list.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return list;
  }

  GatheringDetailViewModel({
    required Invitation initialInvitation,
    required this.onUpdateGlobalMeta,
  }) : _invitation = initialInvitation;

  void updateTitle(String newTitle) {
    _invitation = _invitation.copyWith(title: newTitle);
    onUpdateGlobalMeta(_invitation.id, newTitle, _invitation.imageUrl);
    notifyListeners();
  }

  void updateImage(String newImageUrl) {
    _invitation = _invitation.copyWith(imageUrl: newImageUrl);
    onUpdateGlobalMeta(_invitation.id, _invitation.title, newImageUrl);
    notifyListeners();
  }

  void addSchedule(String location, DateTime dateTime) {
    final newSchedule = GatheringSchedule(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      location: location,
      dateTime: dateTime,
    );
    _schedules.add(newSchedule);
    notifyListeners();
  }

  void voteSchedule(String id, bool attend) {
    final index = _schedules.indexWhere((s) => s.id == id);
    if (index != -1) {
      // Toggle if already selected, or switch
      if (_schedules[index].isAttending == attend) {
        _schedules[index] = _schedules[index].copyWith(isAttending: null);
      } else {
        _schedules[index] = _schedules[index].copyWith(isAttending: attend);
      }
      notifyListeners();
    }
  }

  Future<void> convertToRegular(VoidCallback onSuccess) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 600));
    _isLoading = false;
    notifyListeners();
    onSuccess();
  }

  Future<void> expireInvitation(VoidCallback onSuccess) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 600));
    _isLoading = false;
    notifyListeners();
    onSuccess();
  }
}
