import 'package:flutter/material.dart';
import '../../home/models/invitation.dart';

class GatheringDetailViewModel extends ChangeNotifier {
  final Invitation invitation;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  GatheringDetailViewModel({required this.invitation});

  Future<void> convertToRegular(VoidCallback onSuccess) async {
    _isLoading = true;
    notifyListeners();
    // 백엔드 API 연동 위치 (상태 변경)
    await Future.delayed(const Duration(milliseconds: 600));
    _isLoading = false;
    notifyListeners();
    onSuccess();
  }

  Future<void> expireInvitation(VoidCallback onSuccess) async {
    _isLoading = true;
    notifyListeners();
    // 백엔드 API 연동 위치 (상태 변경)
    await Future.delayed(const Duration(milliseconds: 600));
    _isLoading = false;
    notifyListeners();
    onSuccess();
  }
}
