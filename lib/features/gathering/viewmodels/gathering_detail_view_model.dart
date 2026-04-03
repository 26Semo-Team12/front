import 'package:flutter/material.dart';
import '../../home/models/invitation.dart';
import '../models/gathering.dart';
import '../models/schedule_option.dart';
import '../services/gathering_service.dart';
import '../services/schedule_service.dart';
import '../../auth/services/auth_service.dart';

class GatheringDetailViewModel extends ChangeNotifier {
  final GatheringService _gatheringService = GatheringService();
  final ScheduleService _scheduleService = ScheduleService();
  final AuthService _authService = AuthService();

  String? _currentUserEmail;

  Invitation _invitation;
  Gathering? _gathering;
  final void Function(String id, String? newTitle, String? newImageUrl) onUpdateGlobalMeta;

  Invitation get invitation => _invitation;
  Gathering? get gathering => _gathering;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<ScheduleOption> _scheduleOptions = [];
  List<ScheduleOption> get scheduleOptions => _scheduleOptions;

  // 앨범 이미지 목록 (로컬 경로 또는 URL)
  List<String> _albumImages = [];
  List<String> get albumImages => List.unmodifiable(_albumImages);

  // 구성원 목록 (이름, 프로필 이미지 URL)
  List<Map<String, String>> _members = [];
  List<Map<String, String>> get members => List.unmodifiable(_members);

  // 최근 채팅 메시지 (text, sender, time)
  Map<String, String>? _latestMessage;
  Map<String, String>? get latestMessage => _latestMessage;

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
    _isLoading = true;
    notifyListeners();

    // 현재 유저 이메일 로드
    try {
      final user = await _authService.getMe();
      _currentUserEmail = user.email;
    } catch (_) {}

    final isDemoAccount = _currentUserEmail == 'asdf@asdf.asdf';

    // demo 계정이면 gatheringId 없어도 mock 데이터 주입
    if (isDemoAccount) {
      if (_members.isEmpty) _members = List<Map<String, String>>.from(_demoMembers);
      if (_albumImages.isEmpty) _albumImages = List<String>.from(_demoAlbumImages);
      _isLoading = false;
      notifyListeners();
      return;
    }

    if (gatheringId == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

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

  static const _demoMembers = [
    {'name': '김민준', 'imageUrl': 'https://picsum.photos/seed/m1/100'},
    {'name': '이서연', 'imageUrl': 'https://picsum.photos/seed/m2/100'},
    {'name': '박지호', 'imageUrl': 'https://picsum.photos/seed/m3/100'},
    {'name': '최유나', 'imageUrl': 'https://picsum.photos/seed/m4/100'},
    {'name': '정하은', 'imageUrl': 'https://picsum.photos/seed/m5/100'},
  ];

  static const _defaultMembers = <Map<String, String>>[];  // 서버 연동 후 사용

  static const _demoAlbumImages = [
    'https://picsum.photos/seed/gather1/600/400',
    'https://picsum.photos/seed/gather2/600/400',
    'https://picsum.photos/seed/gather3/600/400',
    'https://picsum.photos/seed/gather4/600/400',
    'https://picsum.photos/seed/gather5/600/400',
  ];

  void updateTitle(String newTitle) {
    _invitation = _invitation.copyWith(title: newTitle);
    onUpdateGlobalMeta(_invitation.id, newTitle, _invitation.imageUrl);
    notifyListeners();
  }

  void updateImage(String newImageUrl) {
    _invitation = _invitation.copyWith(imageUrl: newImageUrl);
    if (!_albumImages.contains(newImageUrl)) {
      _albumImages.insert(0, newImageUrl);
    }
    onUpdateGlobalMeta(_invitation.id, _invitation.title, newImageUrl);
    notifyListeners();
  }

  void setLatestMessage(String text, String sender, String time) {
    _latestMessage = {'text': text, 'sender': sender, 'time': time};
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
