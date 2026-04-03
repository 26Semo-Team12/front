import 'package:flutter/material.dart';
import '../../home/models/invitation.dart';
import '../models/gathering.dart';
import '../models/schedule_option.dart';
import '../services/gathering_service.dart';
import '../services/schedule_service.dart';

class GatheringDetailViewModel extends ChangeNotifier {
  final GatheringService _gatheringService = GatheringService();
  final ScheduleService _scheduleService = ScheduleService();

  Invitation _invitation;
  Gathering? _gathering;
  final void Function(String id, String? newTitle, String? newImageUrl) onUpdateGlobalMeta;

  Invitation get invitation => _invitation;
  Gathering? get gathering => _gathering;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<ScheduleOption> _scheduleOptions = [];
  List<ScheduleOption> get scheduleOptions => _scheduleOptions;

  int? get gatheringId => int.tryParse(_invitation.id);

  List<ScheduleOption> get sortedScheduleOptions {
    final list = List<ScheduleOption>.from(_scheduleOptions);
    list.sort((a, b) => a.startAt.compareTo(b.startAt));
    return list;
  }

  GatheringDetailViewModel({
    required Invitation initialInvitation,
    required this.onUpdateGlobalMeta,
  }) : _invitation = initialInvitation {
    loadData();
  }

  Future<void> loadData() async {
    if (gatheringId == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      _gathering = await _gatheringService.getGatheringDetail(gatheringId!);
      final options = await _scheduleService.getScheduleOptions(gatheringId!);
      _scheduleOptions = options.map((e) => ScheduleOption.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Failed to load gathering data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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

  Future<void> addSchedule(DateTime dateTime) async {
    if (gatheringId == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      await _scheduleService.createScheduleOption(gatheringId!, dateTime);
      await loadData(); // Refresh list
    } catch (e) {
      debugPrint('Failed to add schedule: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> voteSchedule(int optionId, VoteStatus status) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _scheduleService.voteScheduleOption(optionId, status.value);
      await loadData(); // Refresh list
    } catch (e) {
      debugPrint('Failed to vote schedule: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> finalizeSchedule(int optionId) async {
    if (gatheringId == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      await _scheduleService.finalizeSchedule(gatheringId!, optionId);
      await loadData();
    } catch (e) {
      debugPrint('Failed to finalize schedule: $e');
    } finally {
      _isLoading = false;
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
