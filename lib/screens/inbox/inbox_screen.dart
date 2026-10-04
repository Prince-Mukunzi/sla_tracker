import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/animations/animation_helpers.dart';
import '../../core/components/avatar_circle.dart';
import '../../core/components/pressable_scale.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../data/comment_repository.dart';
import '../../models/task.dart';
import '../../providers/comment_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/team_member_provider.dart';
import '../task_detail/task_detail_screen.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen>
    with TickerProviderStateMixin {
  late AnimationController _entranceCtrl;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _entranceCtrl.forward();
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  void _openTask(String taskId) {
    Navigator.of(context)
        .push(SheetRoute(page: TaskDetailScreen(taskId: taskId)))
        .then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(tasksProvider);
    final user = ref.watch(currentUserProvider);
    final commentRepo = ref.read(commentRepositoryProvider);
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Build activity items: recent comments across all tasks
    final activities = <_ActivityItem>[];
    for (final task in tasks) {
      final comments = commentRepo.getComments(task.id);
      for (final comment in comments) {
        final isMention =
            comment.mentions.contains(user?.id ?? 'current_user');
        activities.add(_ActivityItem(
          task: task,
          comment: comment,
          isMention: isMention,
        ));
      }
    }

    // Sort by most recent
    activities.sort((a, b) =>
        b.comment.createdAt.compareTo(a.comment.createdAt));

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
            child: FadeSlideIn(
              parentAnimation: _entranceCtrl,
              interval: const Interval(0.0, 0.2),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Activity',
                  style: AppTypography.displayLarge.copyWith(
                    fontSize: 36,
                    fontWeight: FontWeight.w200,
                    letterSpacing: -1.5,
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(child: const SizedBox(height: 8)),

          SliverToBoxAdapter(
            child: FadeSlideIn(
              parentAnimation: _entranceCtrl,
              interval: const Interval(0.05, 0.25),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  '${activities.length} ${activities.length == 1 ? 'update' : 'updates'}',
                  style: AppTypography.caption.copyWith(
                    fontSize: 13,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: FadeSlideIn(
              parentAnimation: _entranceCtrl,
              interval: const Interval(0.1, 0.3),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Container(
                  height: 0.5,
                  color: AppColors.divider.withValues(alpha: 0.2),
                ),
              ),
            ),
          ),

          if (activities.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 120),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GlowPulse(
                        color: AppColors.white,
                        radius: 36,
                        period: const Duration(milliseconds: 3000),
                        child: Floating(
                          amplitude: 4,
                          period: const Duration(milliseconds: 4000),
                          child: Icon(LucideIcons.bellOff,
                              size: 32, color: AppColors.textTertiary),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No activity yet',
                        style: AppTypography.headingSmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Comments and mentions will appear here',
                        style: AppTypography.caption.copyWith(
                          fontSize: 13,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverList.builder(
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final activity = activities[index];
                return SliverStaggerItem(
                  index: index,
                  child: PressableScale(
                    onTap: () => _openTask(activity.task.id),
                    pressedScale: 0.99,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.divider.withValues(alpha: 0.08),
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar
                            AvatarCircle(
                              initials: activity.comment.authorInitials,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: activity.comment.authorName
                                                    .split(' ')
                                                    .first,
                                                style: AppTypography.labelSmall
                                                    .copyWith(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              TextSpan(
                                                text: activity.isMention
                                                    ? ' mentioned you in '
                                                    : ' commented on ',
                                                style: AppTypography.bodyMedium
                                                    .copyWith(
                                                  fontSize: 13,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                              TextSpan(
                                                text: activity.task.title,
                                                style: AppTypography.labelSmall
                                                    .copyWith(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    activity.comment.content,
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontSize: 13,
                                      color: AppColors.textTertiary,
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatTimeAgo(activity.comment.createdAt),
                                    style: AppTypography.caption.copyWith(
                                      fontSize: 11,
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (activity.isMention)
                              Padding(
                                padding: const EdgeInsets.only(left: 8, top: 2),
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

          SliverToBoxAdapter(
            child: SizedBox(height: bottomPadding + 120),
          ),
        ],
      ),
    );
  }

}

class _ActivityItem {
  final Task task;
  final Comment comment;
  final bool isMention;

  const _ActivityItem({
    required this.task,
    required this.comment,
    required this.isMention,
  });
}
