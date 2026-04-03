import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/user_profile.dart';
import '../models/evaluation.dart';
import '../viewmodels/evaluation_view_model.dart';
import '../../../core/utils/image_utils.dart';

class EvaluationScreen extends StatelessWidget {
  final int gatheringId;
  final List<UserProfile> participants;
  final int currentUserId;

  const EvaluationScreen({
    super.key,
    required this.gatheringId,
    required this.participants,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EvaluationViewModel(
        gatheringId: gatheringId,
        participants: participants,
        currentUserId: currentUserId,
      ),
      child: const _EvaluationScreenContent(),
    );
  }
}

class _EvaluationScreenContent extends StatefulWidget {
  const _EvaluationScreenContent();

  @override
  State<_EvaluationScreenContent> createState() => _EvaluationScreenContentState();
}

class _EvaluationScreenContentState extends State<_EvaluationScreenContent> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<EvaluationViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('팀원 평가', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: viewModel.evaluatees.isEmpty
          ? const Center(child: Text('평가할 팀원이 없습니다.', style: TextStyle(color: Colors.black54)))
          : Column(
              children: [
                _buildParticipantList(context, viewModel),
                const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildForm(context, viewModel),
                  ),
                ),
                _buildBottomButton(context, viewModel),
              ],
            ),
    );
  }

  Widget _buildParticipantList(BuildContext context, EvaluationViewModel viewModel) {
    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: viewModel.evaluatees.length,
        itemBuilder: (context, index) {
          final evaluatee = viewModel.evaluatees[index];
          final isActive = viewModel.activeEvaluateeId == evaluatee.id;
          final isCompleted = viewModel.completedEvaluationIds.contains(evaluatee.id);

          return GestureDetector(
            onTap: () {
              if (isCompleted) return; // 알림/토스트 띄울 수도 있음
              viewModel.setActiveEvaluatee(evaluatee.id);
              // 커스텀 로컬 상태 리셋
              _commentController.clear();
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 60,
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isActive ? const Color(0xFFD6706D) : Colors.transparent,
                            width: 2,
                          ),
                          image: DecorationImage(
                            image: resolveImage(
                              evaluatee.profileImageUrl.isNotEmpty
                                  ? evaluatee.profileImageUrl
                                  : 'https://via.placeholder.com/150',
                            ),
                            fit: BoxFit.cover,
                          ),
                          color: Colors.grey.shade200,
                        ),
                        foregroundDecoration: isCompleted
                            ? BoxDecoration(
                                color: Colors.white.withOpacity(0.6),
                                shape: BoxShape.circle,
                              )
                            : null,
                      ),
                      if (isCompleted)
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Color(0xFFD6706D),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, size: 12, color: Colors.white),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    evaluatee.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? const Color(0xFFD6706D) : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context, EvaluationViewModel viewModel) {
    if (viewModel.activeEvaluateeId == null) {
      return const SizedBox.shrink();
    }
    
    final activeEvaluatee = viewModel.evaluatees.firstWhere((e) => e.id == viewModel.activeEvaluateeId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${activeEvaluatee.name}님과의 모임은 어떠셨나요?',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 24),

        // Positive Tags
        RichText(
          text: const TextSpan(
            text: '좋았던 점 ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
            children: [
              TextSpan(text: '(최대 3개)', style: TextStyle(fontSize: 14, color: Colors.black45, fontWeight: FontWeight.normal)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PositiveTag.values.map((tag) {
            final isSelected = viewModel.getActivePositiveTags().contains(tag);
            return FilterChip(
              label: Text(tag.label),
              selected: isSelected,
              onSelected: (_) => viewModel.togglePositiveTag(tag),
              selectedColor: const Color(0xFFD6706D).withOpacity(0.2),
              checkmarkColor: const Color(0xFFD6706D),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFFD6706D) : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? const Color(0xFFD6706D) : Colors.grey.shade300,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),

        // Negative Tags
        RichText(
          text: const TextSpan(
            text: '아쉬웠던 점 ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
            children: [
              TextSpan(text: '(최대 3개)', style: TextStyle(fontSize: 14, color: Colors.black45, fontWeight: FontWeight.normal)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: NegativeTag.values.map((tag) {
            final isSelected = viewModel.getActiveNegativeTags().contains(tag);
            return FilterChip(
              label: Text(tag.label),
              selected: isSelected,
              onSelected: (_) => viewModel.toggleNegativeTag(tag),
              selectedColor: Colors.grey.shade800,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? Colors.grey.shade800 : Colors.grey.shade300,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),

        // Comment
        const Text(
          '추가 의견 (선택)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _commentController,
          maxLength: 300,
          maxLines: 4,
          onChanged: (text) => viewModel.updateComment(text),
          decoration: InputDecoration(
            hintText: '이 팀원과의 모임에서 기억에 남는 점을 적어주세요.',
            hintStyle: const TextStyle(color: Colors.black38),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD6706D)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton(BuildContext context, EvaluationViewModel viewModel) {
    if (viewModel.activeEvaluateeId == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: viewModel.canSubmitActive && !viewModel.isSubmitting
                ? () {
                    viewModel.submitActiveEvaluation(() {
                      // All completed
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('모든 팀원의 평가가 완료되었습니다.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    });
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD6706D),
              disabledBackgroundColor: Colors.grey.shade300,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: viewModel.isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    '평가 제출',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
          ),
        ),
      ),
    );
  }
}
