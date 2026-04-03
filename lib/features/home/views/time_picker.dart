// lib/features/home/views/time_picker.dart
import 'package:flutter/material.dart';
import 'package:front/core/models/user_profile.dart';

const int _kStartHour = 9;
const int _kEndHour = 22;
const int _kHourCount = _kEndHour - _kStartHour + 1; // 14

class TimePicker extends StatefulWidget {
  final List<TimeSlot> initialSlots;
  final void Function(List<TimeSlot>) onConfirm;

  const TimePicker({
    super.key,
    required this.initialSlots,
    required this.onConfirm,
  });

  @override
  State<TimePicker> createState() => _TimePickerState();
}

class _TimePickerState extends State<TimePicker> {
  late Set<TimeSlot> _selected;
  TimeSlot? _dragStart;
  TimeSlot? _dragCurrent;
  bool? _dragSelectMode;

  static const List<String> _days = ['월', '화', '수', '목', '금', '토', '일'];
  static const double _labelW = 28.0;
  static const double _headerH = 26.0;
  static const double _cellH = 26.0;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSlots
        .where((s) => s.hourIndex >= _kStartHour && s.hourIndex <= _kEndHour)
        .toSet();
  }

  TimeSlot? _slotAt(Offset local, double cellW) {
    final x = local.dx - _labelW;
    final y = local.dy - _headerH;
    if (x < 0 || y < 0) return null;
    final col = (x / cellW).floor();
    final rowOffset = (y / _cellH).floor();
    if (col < 0 || col >= 7 || rowOffset < 0 || rowOffset >= _kHourCount) return null;
    return TimeSlot(weekday: col, hourIndex: _kStartHour + rowOffset);
  }

  Set<TimeSlot> _rectSlots(TimeSlot a, TimeSlot b) {
    final c0 = a.weekday < b.weekday ? a.weekday : b.weekday;
    final c1 = a.weekday > b.weekday ? a.weekday : b.weekday;
    final r0 = a.hourIndex < b.hourIndex ? a.hourIndex : b.hourIndex;
    final r1 = a.hourIndex > b.hourIndex ? a.hourIndex : b.hourIndex;
    return {
      for (var c = c0; c <= c1; c++)
        for (var r = r0; r <= r1; r++) TimeSlot(weekday: c, hourIndex: r),
    };
  }

  bool _inRect(TimeSlot s) {
    if (_dragStart == null || _dragCurrent == null) return false;
    final c0 = _dragStart!.weekday < _dragCurrent!.weekday ? _dragStart!.weekday : _dragCurrent!.weekday;
    final c1 = _dragStart!.weekday > _dragCurrent!.weekday ? _dragStart!.weekday : _dragCurrent!.weekday;
    final r0 = _dragStart!.hourIndex < _dragCurrent!.hourIndex ? _dragStart!.hourIndex : _dragCurrent!.hourIndex;
    final r1 = _dragStart!.hourIndex > _dragCurrent!.hourIndex ? _dragStart!.hourIndex : _dragCurrent!.hourIndex;
    return s.weekday >= c0 && s.weekday <= c1 && s.hourIndex >= r0 && s.hourIndex <= r1;
  }

  void _commitDrag() {
    if (_dragStart == null || _dragCurrent == null || _dragSelectMode == null) return;
    final rect = _rectSlots(_dragStart!, _dragCurrent!);
    setState(() {
      if (_dragSelectMode!) {
        _selected.addAll(rect);
      } else {
        _selected.removeAll(rect);
      }
      _dragStart = null;
      _dragCurrent = null;
      _dragSelectMode = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
        // LayoutBuilder로 실제 사용 가능한 너비를 측정
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 셀 너비 = (사용 가능 너비 - 레이블 너비) / 7
            final cellW = (constraints.maxWidth - _labelW) / 7;
            final gridH = _headerH + _cellH * _kHourCount;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('모임 가능 시간 선택',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                const Text('드래그로 범위 선택',
                    style: TextStyle(fontSize: 10, color: Colors.grey)),
                const SizedBox(height: 10),
                SizedBox(
                  width: constraints.maxWidth,
                  height: gridH,
                  child: Listener(
                    onPointerDown: (e) {
                      final slot = _slotAt(e.localPosition, cellW);
                      if (slot == null) return;
                      setState(() {
                        _dragStart = slot;
                        _dragCurrent = slot;
                        _dragSelectMode = !_selected.contains(slot);
                      });
                    },
                    onPointerMove: (e) {
                      final slot = _slotAt(e.localPosition, cellW);
                      if (slot != null && slot != _dragCurrent) {
                        setState(() => _dragCurrent = slot);
                      }
                    },
                    onPointerUp: (_) => _commitDrag(),
                    onPointerCancel: (_) => _commitDrag(),
                    child: _buildGrid(cellW),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('취소'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        widget.onConfirm(_selected.toList());
                        Navigator.of(context).pop();
                      },
                      child: const Text('확인'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildGrid(double cellW) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 요일 헤더
        Row(
          children: [
            SizedBox(width: _labelW, height: _headerH),
            ..._days.map((d) => SizedBox(
                  width: cellW,
                  height: _headerH,
                  child: Center(
                    child: Text(d,
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                )),
          ],
        ),
        // 시간 행
        ...List.generate(_kHourCount, (i) {
          final hour = _kStartHour + i;
          return Row(
            children: [
              SizedBox(
                width: _labelW,
                height: _cellH,
                child: Center(
                  child: Text(
                    hour.toString().padLeft(2, '0'),
                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                  ),
                ),
              ),
              ...List.generate(7, (weekday) {
                final slot = TimeSlot(weekday: weekday, hourIndex: hour);
                final sel = _selected.contains(slot);
                final inRect = _inRect(slot);
                final Color color;
                if (inRect && _dragSelectMode != null) {
                  color = _dragSelectMode! ? const Color(0xFF7B68EE) : Colors.grey.shade300;
                } else {
                  color = sel ? const Color(0xFF7B68EE) : Colors.grey.shade200;
                }
                return Container(
                  width: cellW,
                  height: _cellH,
                  padding: const EdgeInsets.all(1),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                      border: inRect
                          ? Border.all(
                              color: const Color(0xFF7B68EE).withValues(alpha: 0.5),
                              width: 1)
                          : null,
                    ),
                  ),
                );
              }),
            ],
          );
        }),
      ],
    );
  }
}
