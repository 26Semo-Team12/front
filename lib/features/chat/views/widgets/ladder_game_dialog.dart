import 'package:flutter/material.dart';

class _Participant {
  final String name;
  bool isIncluded = true;

  _Participant(this.name);
}

class LadderGameDialog extends StatefulWidget {
  final ValueChanged<String> onResultSelected;

  const LadderGameDialog({super.key, required this.onResultSelected});

  @override
  State<LadderGameDialog> createState() => _LadderGameDialogState();
}

class _LadderGameDialogState extends State<LadderGameDialog> {
  final List<_Participant> _pool = [
    _Participant('이동진'),
    _Participant('조르디'),
    _Participant('슈퍼 개발자'),
    _Participant('플러터 장인'),
    _Participant('팀장님'),
  ];
  
  final List<TextEditingController> _resultControllers = [];

  @override
  void initState() {
    super.initState();
    _syncGame();
  }

  @override
  void dispose() {
    for (var c in _resultControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _syncGame() {
    int activeCount = _pool.where((p) => p.isIncluded).length;

    while (_resultControllers.length < activeCount) {
      final text = _resultControllers.isEmpty ? '당첨' : '꽝';
      _resultControllers.add(TextEditingController(text: text));
    }
    
    while (_resultControllers.length > activeCount) {
      final lastController = _resultControllers.removeLast();
      lastController.dispose();
    }
  }

  void _toggleParticipant(_Participant p) {
    setState(() {
      p.isIncluded = !p.isIncluded;
      _syncGame();
    });
  }

  void _calculateResult() {
    final activeParticipants = _pool.where((p) => p.isIncluded).toList();
    if (activeParticipants.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('참여자를 2명 이상 선택해주세요.')),
      );
      return;
    }

    for (var controller in _resultControllers) {
      if (controller.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('모든 항목을 입력해주세요.')),
        );
        return;
      }
    }

    final results = _resultControllers.map((c) => c.text.trim()).toList();
    results.shuffle();
    
    final buffer = StringBuffer();
    buffer.writeln('🎉 [사다리게임 결과]');
    for (int i = 0; i < activeParticipants.length; i++) {
      buffer.writeln('${activeParticipants[i].name}: ${results[i]}');
    }
    
    widget.onResultSelected(buffer.toString().trim());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final activeParticipants = _pool.where((p) => p.isIncluded).toList();
    final activeCount = activeParticipants.length;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black87, width: 2),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '사다리게임',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _pool.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  return _buildParticipantAvatar(_pool[index]);
                },
              ),
            ),
            const Divider(color: Colors.black54, height: 24),

            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: activeCount < 2 
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('2명 이상 선택해주세요.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      )
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(activeCount, (index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 80,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.black87, width: 2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  activeParticipants[index].name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                              ),
                              Container(
                                width: 2,
                                height: 100,
                                color: Colors.black87,
                              ),
                              Container(
                                width: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.black87, width: 2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: TextField(
                                  controller: _resultControllers[index],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.black87, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      backgroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('돌아가기', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    onPressed: _calculateResult,
                    child: const Text('사다리 시작', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantAvatar(_Participant p) {
    return GestureDetector(
      onTap: () => _toggleParticipant(p),
      child: Opacity(
        opacity: p.isIncluded ? 1.0 : 0.3,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.black87,
                  child: Icon(Icons.person, color: Colors.white, size: 24),
                ),
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: p.isIncluded ? Colors.redAccent : Colors.blueGrey,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Icon(
                      p.isIncluded ? Icons.remove : Icons.add,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 44,
              child: Text(
                p.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: p.isIncluded ? FontWeight.bold : FontWeight.normal,
                  color: p.isIncluded ? Colors.black87 : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
