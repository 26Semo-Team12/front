import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/gathering_detail_view_model.dart';

class MysteryView extends StatefulWidget {
  const MysteryView({super.key});

  @override
  State<MysteryView> createState() => _MysteryViewState();
}

class _MysteryViewState extends State<MysteryView> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this);
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCirc));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));
    
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.year}.${dt.month.toString().padLeft(2,'0')}.${dt.day.toString().padLeft(2,'0')} $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GatheringDetailViewModel>();
    final inv = viewModel.invitation;

    return Container(
      width: double.infinity,
      color: Colors.black,
      child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnim.value,
                    child: Transform.scale(
                      scale: _scaleAnim.value,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.mail_lock_outlined, color: Color(0xFFD6706D), size: 64),
                            const SizedBox(height: 32),
                            const Text(
                              '비밀 모임',
                              style: TextStyle(color: Colors.white54, fontSize: 18, letterSpacing: 4, decoration: TextDecoration.none),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              inv.location,
                              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, decoration: TextDecoration.none),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _formatDateTime(inv.dateTime),
                              style: const TextStyle(color: Color(0xFFD6706D), fontSize: 20, fontWeight: FontWeight.w500, decoration: TextDecoration.none),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD6706D),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: viewModel.isLoading ? null : () => viewModel.convertToRegular(() => Navigator.pop(context)),
                      child: viewModel.isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                          : const Text('정기 모임으로 전환', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: viewModel.isLoading ? null : () => viewModel.expireInvitation(() => Navigator.pop(context)),
                      child: const Text('만료시키기', style: TextStyle(color: Colors.white54, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
