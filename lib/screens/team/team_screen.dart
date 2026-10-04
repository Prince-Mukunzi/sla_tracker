import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/animations/animation_helpers.dart';
import '../../core/components/avatar_circle.dart';
import '../../core/components/bottom_sheet_handle.dart';
import '../../core/components/dismissible_backgrounds.dart';
import '../../core/components/pressable_scale.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../models/team_member.dart';
import '../../providers/team_member_provider.dart';

class TeamScreen extends ConsumerStatefulWidget {
  const TeamScreen({super.key});

  @override
  ConsumerState<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends ConsumerState<TeamScreen> {
  void _showAddMember() {
    final nameCtrl = TextEditingController();
    final roleCtrl = TextEditingController();

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => _AddMemberSheet(
        title: 'Add Member',
        nameCtrl: nameCtrl,
        roleCtrl: roleCtrl,
        buttonLabel: 'Add',
        onSave: () async {
          final name = nameCtrl.text.trim();
          final role = roleCtrl.text.trim();
          if (name.length < 2) return;

          final member = TeamMember(
            id: 'member_${DateTime.now().millisecondsSinceEpoch}',
            name: name,
            role: role.isNotEmpty ? role : 'Member',
            avatarInitials: initialsFrom(name),
          );

          await ref.read(teamMemberRepositoryProvider).saveMember(member);
          ref.invalidate(teamMembersProvider);
          if (!ctx.mounted) return;
          Navigator.of(ctx).pop();
          setState(() {});
        },
      ),
    );
  }

  void _showEditMember(TeamMember member) {
    final nameCtrl = TextEditingController(text: member.name);
    final roleCtrl = TextEditingController(text: member.role);

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => _AddMemberSheet(
        title: 'Edit Member',
        nameCtrl: nameCtrl,
        roleCtrl: roleCtrl,
        buttonLabel: 'Save',
        onSave: () async {
          final name = nameCtrl.text.trim();
          final role = roleCtrl.text.trim();
          if (name.length < 2) return;

          final updated = TeamMember(
            id: member.id,
            name: name,
            role: role.isNotEmpty ? role : 'Member',
            avatarInitials: initialsFrom(name),
          );

          await ref.read(teamMemberRepositoryProvider).saveMember(updated);
          ref.invalidate(teamMembersProvider);
          if (!ctx.mounted) return;
          Navigator.of(ctx).pop();
          setState(() {});
        },
      ),
    );
  }

  Future<void> _deleteMember(TeamMember member) async {
    HapticFeedback.heavyImpact();
    await ref.read(teamMemberRepositoryProvider).deleteMember(member.id);
    ref.invalidate(teamMembersProvider);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(teamMembersProvider);
    final currentUser = ref.watch(currentUserProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    final otherMembers =
        members.where((m) => m.id != 'current_user').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: topPadding + 20)),

          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Workspace',
                      style: AppTypography.displayLarge.copyWith(
                        fontSize: 36,
                        fontWeight: FontWeight.w200,
                        letterSpacing: -1.5,
                      ),
                    ),
                  ),
                  PressableScale(
                    onTap: _showAddMember,
                    pressedScale: 0.92,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.plus,
                              size: 14, color: AppColors.black),
                          const SizedBox(width: 4),
                          Text(
                            'Add',
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.black,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(child: const SizedBox(height: 8)),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '${members.length} ${members.length == 1 ? 'member' : 'members'}',
                style: AppTypography.caption.copyWith(
                  fontSize: 13,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ),

          // Divider
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Container(
                height: 0.5,
                color: AppColors.divider.withValues(alpha: 0.3),
              ),
            ),
          ),

          // You (current user)
          if (currentUser != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _MemberRow(
                  member: currentUser,
                  isYou: true,
                ),
              ),
            ),

          // Other members with swipe gestures
          SliverList.builder(
            itemCount: otherMembers.length,
            itemBuilder: (context, index) {
              final member = otherMembers[index];
              return SliverStaggerItem(
                index: index,
                child: ClipRRect(
                child: Dismissible(
                  key: ValueKey('member_${member.id}'),
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.startToEnd) {
                      _showEditMember(member);
                      return false;
                    } else {
                      _deleteMember(member);
                      return false;
                    }
                  },
                  background: const EditSwipeBackground(),
                  secondaryBackground: const DeleteSwipeBackground(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _MemberRow(member: member),
                  ),
                ),
              ),
              );
            },
          ),

          SliverToBoxAdapter(
            child: SizedBox(
                height: MediaQuery.of(context).padding.bottom + 100),
          ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final TeamMember member;
  final bool isYou;

  const _MemberRow({
    required this.member,
    this.isYou = false,
  });

  @override
  Widget build(BuildContext context) {
    return TiltCard(
      maxAngle: 0.018,
      liftScale: 1.01,
      child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.divider.withValues(alpha: 0.12),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          AvatarCircle(
            initials: member.avatarInitials,
            size: 36,
            fontSize: 12,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      member.name,
                      style: AppTypography.bodyLarge.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (isYou) ...[
                      const SizedBox(width: 8),
                      Text(
                        'You',
                        style: AppTypography.caption.copyWith(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  member.role,
                  style: AppTypography.caption.copyWith(
                    fontSize: 13,
                    color: AppColors.textTertiary,
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

class _AddMemberSheet extends StatelessWidget {
  final String title;
  final TextEditingController nameCtrl;
  final TextEditingController roleCtrl;
  final String buttonLabel;
  final VoidCallback onSave;

  const _AddMemberSheet({
    required this.title,
    required this.nameCtrl,
    required this.roleCtrl,
    required this.buttonLabel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
        ),
        child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BottomSheetHandle(title: title),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
                cursorColor: AppColors.white,
                decoration: InputDecoration(
                  hintText: 'Name',
                  hintStyle: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  border: InputBorder.none,
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.divider.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.white),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: roleCtrl,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
                cursorColor: AppColors.white,
                decoration: InputDecoration(
                  hintText: 'Role (optional)',
                  hintStyle: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  border: InputBorder.none,
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.divider.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.white),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              PressableScale(
                onTap: onSave,
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      buttonLabel,
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
