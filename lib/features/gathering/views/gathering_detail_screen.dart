import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../home/models/invitation.dart';
import '../../home/viewmodels/home_view_model.dart';
import '../viewmodels/gathering_detail_view_model.dart';
import 'mystery_view.dart';
import 'history_view.dart';
import 'regular_view.dart';

class GatheringDetailScreen extends StatelessWidget {
  final Invitation invitation;

  const GatheringDetailScreen({super.key, required this.invitation});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => GatheringDetailViewModel(
        initialInvitation: invitation,
        onUpdateGlobalMeta: (id, title, img) {
          try {
            ctx.read<HomeViewModel>().updateInvitationMeta(id, newTitle: title, newImageUrl: img);
          } catch (_) {}
        },
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: _buildContentForType(invitation.type),
      ),
    );
  }

  Widget _buildContentForType(InvitationType type) {
    switch (type) {
      case InvitationType.newInvitation:
        return const MysteryView();
      case InvitationType.expired:
        return const HistoryView();
      case InvitationType.longTerm:
        return const RegularView();
    }
  }
}
