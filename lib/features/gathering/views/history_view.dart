import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/gathering_detail_view_model.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  String _formatDateTime(DateTime dt) {
    return '${dt.year}.${dt.month.toString().padLeft(2,'0')}.${dt.day.toString().padLeft(2,'0')}';
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
    );
  }
}
