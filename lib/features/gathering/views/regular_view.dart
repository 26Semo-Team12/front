import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/gathering_detail_view_model.dart';

class RegularView extends StatelessWidget {
  const RegularView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GatheringDetailViewModel>();
    final inv = viewModel.invitation;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.face, color: Colors.black, size: 28),
            SizedBox(width: 8),
            Text('앱 이름', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
            onPressed: () {},
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.0),
          child: Container(color: Colors.black, height: 2),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  inv.title.isNotEmpty ? inv.title : '정기 모임',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                Row(
                  children: const [
                    Icon(Icons.local_fire_department, color: Colors.black, size: 20),
                    SizedBox(width: 4),
                    Text(
                      'D+12',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: const [
                 Text('앨범', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                 Icon(Icons.chevron_right, size: 20),
               ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 140,
              padding: const EdgeInsets.only(top: 16, bottom: 16, left: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 4,
                itemBuilder: (ctx, i) {
                  return Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade500,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: const [
                 Text('일정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                 Icon(Icons.add, size: 20),
               ],
            ),
            const SizedBox(height: 32),
            Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: const [
                 Text('채팅방', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                 Icon(Icons.chevron_right, size: 20),
               ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('최근 채팅', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildChatBubble('흠'),
                            _buildChatBubble('이해한 것 같아요'),
                            _buildChatBubble('더 궁금한 점이 있으면 도움말 센터에 문의할게요'),
                          ],
                        ),
                      ),
                      const Text('13분 전', style: TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.bold)),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 0, left: 0, right: 0,
                    child: CustomPaint(
                      painter: _EnvelopePainter(),
                      size: const Size(double.infinity, 50),
                    ),
                  ),
                  const Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        '모임에게 온 초대장(다른 모임과의 만남을 주선)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
         color: Colors.white.withValues(alpha: 0.9),
         borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text, style: const TextStyle(fontSize: 14, color: Colors.black87)),
    );
  }
}

class _EnvelopePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width / 2, 50);
    path.lineTo(size.width, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
