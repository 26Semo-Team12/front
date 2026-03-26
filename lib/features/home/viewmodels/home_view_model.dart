// lib/features/home/viewmodels/home_view_model.dart

import 'package:flutter/material.dart';
import '../../../core/models/user_profile.dart'; // core에서 공통 모델 가져오기
import '../models/invitation.dart'; // home 전용 모델 가져오기

class HomeViewModel extends ChangeNotifier {
  UserProfile? _currentUser;
  List<Invitation> _invitations = [];
  int _selectedTabIndex = 1;
  int _currentPageIndex = 0;

  UserProfile? get currentUser => _currentUser;
  List<Invitation> get invitations => _invitations;
  int get selectedTabIndex => _selectedTabIndex;
  int get currentPageIndex => _currentPageIndex;

  HomeViewModel() {
    _fetchMockData();
  }

  void _fetchMockData() {
    _currentUser = UserProfile(
      name: '방황하는 조르디123',
      profileImageUrl:
          'https://images.unsplash.com/photo-1599566150163-29194dcaad36?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NHx8YXZhdGFyfGVufDB8fDB8fHww&auto=format&fit=crop&w=800&q=60',
      interests: ['배드민턴', '클라이밍', '밴드'],
      ageRange: '20대',
      gender: '여자',
      rating: 4.5,
    );

    _invitations = [
      Invitation(
        title: '라켓은 랠리를 싫어해.',
        description: '배드민턴 초보 대모임 (여의도)',
        isNew: true,
      ),
      Invitation(
        title: '수요 스릴러',
        description: '스릴러 영화 정기 소모임 (용산)',
        isNew: true,
        isRegular: true,
      ),
      Invitation(title: '만료된 초대장 1', description: '지난 모임 1', isRegular: true),
    ];

    notifyListeners();
  }

  void changeTab(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }

  void changePage(int index) {
    _currentPageIndex = index;
    notifyListeners();
  }

  void editProfile(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('프로필 편집 화면으로 이동')));
  }
}
