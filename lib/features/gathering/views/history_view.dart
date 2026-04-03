import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/gathering_detail_view_model.dart';
import '../../evaluation/views/evaluation_screen.dart';
import '../../../core/models/user_profile.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  String _formatDateTime(DateTime dt) {
    final kst = dt.isUtc ? dt.add(const Duration(hours: 9)) : dt;
    return '${kst.year}.${kst.month.toString().padLeft(2,'0')}.${kst.day.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GatheringDetailViewModel>();
    final inv = viewModel.invitation;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('종료된 모임', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                   const Icon(Icons.history, color: Colors.grey, size: 48),
                   const SizedBox(height: 16),
                   Text(
                     inv.location,
                     style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black54),
                     textAlign: TextAlign.center,
                   ),
                   const SizedBox(height: 8),
                   Text(
                     _formatDateTime(inv.dateTime),
                     style: const TextStyle(fontSize: 16, color: Colors.black38),
                   ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            const Text(
              '마음에 들지 않았던 이유',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '참여율이 저조했고, 주요 활동 지역과 거리가 멀어서 다음에는 더 가까운 모임에 참석하고 싶습니다. (Mock Memo Data)',
                style: TextStyle(color: Colors.black54, height: 1.6, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: ElevatedButton(
            onPressed: () {
              final mockParticipants = [
                UserProfile(id: 1, email: 'me@test.com', name: '나자신', region: '서울', profileImageUrl: 'https://api.dicebear.com/7.x/notionists/png?seed=1'),
                UserProfile(id: 2, email: 'lee@test.com', name: '이민호', region: '서울', profileImageUrl: 'https://api.dicebear.com/7.x/notionists/png?seed=2'),
                UserProfile(id: 3, email: 'kim@test.com', name: '김지은', region: '서울', profileImageUrl: 'https://api.dicebear.com/7.x/notionists/png?seed=3'),
                UserProfile(id: 4, email: 'park@test.com', name: '박서준', region: '서울', profileImageUrl: 'https://api.dicebear.com/7.x/notionists/png?seed=4'),
              ];
              
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EvaluationScreen(
                    gatheringId: int.tryParse(inv.id) ?? 0,
                    participants: mockParticipants,
                    currentUserId: 1,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD6706D),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text(
              '팀원 평가하기',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
