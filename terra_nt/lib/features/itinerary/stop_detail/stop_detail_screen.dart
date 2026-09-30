import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/elevation.dart';
import '../../../core/theme/metrics.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/util/maps_url.dart';
import '../../../core/util/tag_colors.dart';
import '../../../data/models/stop.dart';
import '../../../data/repositories/notifiers.dart';
import '../../../data/seed/place_images.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_icon.dart';
import '../../../shared/widgets/entrance.dart';
import '../../../shared/widgets/tag_dot.dart';
import '../widgets/plan_entry_list.dart';
import '../widgets/result_stop_list.dart' show StopPicture;

typedef StopMapsLauncher = Future<bool> Function(Uri url);

/// Details for one itinerary stop, pushed above the Plan AI stack.
class StopDetailScreen extends ConsumerWidget {
  const StopDetailScreen({
    super.key,
    required this.stop,
    required this.originalIndex,
    this.launcher = launchUrl,
  });

  final Stop stop;
  final int originalIndex;
  final StopMapsLauncher launcher;

  void _goBack(BuildContext context) {
    Navigator.of(context).pop();
  }

  void _toggleSkip(BuildContext context, WidgetRef ref) {
    HapticFeedback.lightImpact();
    ref.read(itineraryNotifierProvider.notifier).toggleSkipped(originalIndex);
    _goBack(context);
  }

  Future<void> _navigate() async {
    final url = singleDestinationUrl(stop);
    if (url != null) await launcher(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skipped = ref
        .watch(itineraryNotifierProvider)
        .skipped
        .contains(originalIndex);

    return Scaffold(
      key: const ValueKey('stop-detail-screen'),
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _Hero(
              stop: stop,
              originalIndex: originalIndex,
              onBack: () => _goBack(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppMetrics.stopDetailContentPadding,
                  AppMetrics.stopDetailContentPadding,
                  AppMetrics.stopDetailContentPadding,
                  AppSpacing.lg,
                ),
                // The hero arrives with the page; the sections below it follow
                // in reading order, which is why the first takes slot 1
                // (`docs/PRD.md` D18).
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Entrance(index: 1, child: _StopHeading(stop: stop)),
                    const SizedBox(height: AppMetrics.stopDetailContentGap),
                    Entrance(
                      index: 2,
                      child: stop.detailedPlan.isEmpty
                          ? Text(
                              'No detailed plan for this stop.',
                              key: const ValueKey('detailed-plan-empty'),
                              style: AppType.bodySm.copyWith(
                                color: AppColors.inkTertiary,
                              ),
                            )
                          : PlanEntryList(
                              key: const ValueKey('stop-detail-plan'),
                              entries: stop.detailedPlan,
                            ),
                    ),
                    const SizedBox(height: AppMetrics.stopDetailContentGap),
                    Entrance(index: 3, child: _TagList(tags: stop.tags)),
                    const SizedBox(height: AppMetrics.stopDetailContentGap),
                    Entrance(index: 4, child: _InfoCard(stop: stop)),
                    const SizedBox(height: AppMetrics.stopDetailContentGap),
                    Entrance(index: 5, child: _AiNote(note: stop.aiNote)),
                  ],
                ),
              ),
            ),
            _Footer(
              skipped: skipped,
              onSkip: () => _toggleSkip(context, ref),
              onNavigate: _navigate,
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.stop,
    required this.originalIndex,
    required this.onBack,
  });

  final Stop stop;
  final int originalIndex;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppMetrics.stopDetailHeroHeight,
      child: Stack(
        children: [
          StopPicture(
            originalIndex: originalIndex,
            height: AppMetrics.stopDetailHeroHeight,
            image: stop.photoUrl ?? placeImageFor(stop.name, tags: stop.tags),
          ),
          Positioned(
            // The hero stays full-bleed under the status bar; the only control
            // on top of it does not.
            top: AppSpacing.md + MediaQuery.viewPaddingOf(context).top,
            left: AppSpacing.md,
            child: GestureDetector(
              key: const ValueKey('stop-detail-back-button'),
              behavior: HitTestBehavior.opaque,
              onTap: onBack,
              // Painted at the prototype's 36px circle, in its measured
              // position, inside a 48px target that grows away from the corner.
              child: SizedBox(
                width: AppMetrics.minTouchTarget,
                height: AppMetrics.minTouchTarget,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    key: const ValueKey('stop-detail-back-button-visual'),
                    width: AppMetrics.stopDetailBackButtonSize,
                    height: AppMetrics.stopDetailBackButtonSize,
                    decoration: BoxDecoration(
                      color: AppColors.stopDetailHeroScrim,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(
                        color: AppColors.hairlineStrong,
                        width: AppElevation.hairlineWidth,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const AppIcon(
                      LucideIcons.arrow_left,
                      size: AppMetrics.iconLg,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StopHeading extends StatelessWidget {
  const _StopHeading({required this.stop});

  final Stop stop;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          stop.name,
          key: const ValueKey('stop-detail-name'),
          style: AppType.cardTitle.copyWith(color: AppColors.ink),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          stop.subtitle,
          key: const ValueKey('stop-detail-subtitle'),
          style: AppType.bodySm.copyWith(color: AppColors.inkSubtle),
        ),
      ],
    );
  }
}

class _TagList extends StatelessWidget {
  const _TagList({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      key: const ValueKey('stop-detail-tags'),
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final tag in tags)
          TagDot(color: tagColor(tag), label: tag, bordered: true),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.stop});

  final Stop stop;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('stop-detail-info-card'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppMetrics.padRowY,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        border: Border.all(
          color: AppColors.hairline,
          width: AppElevation.hairlineWidth,
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InfoRow(label: 'Hours', value: stop.hours),
          if (stop.fee != null) ...[
            const SizedBox(height: AppMetrics.stopDetailInfoGap),
            Container(
              height: AppElevation.hairlineWidth,
              color: AppColors.hairline,
            ),
            const SizedBox(height: AppMetrics.stopDetailInfoGap),
            _InfoRow(label: 'Park entry fee', value: stop.fee!),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppType.bodySm.copyWith(color: AppColors.inkSubtle)),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          value,
          textAlign: TextAlign.left,
          style: AppType.bodySm.copyWith(color: AppColors.ink),
        ),
      ],
    );
  }
}

class _AiNote extends StatelessWidget {
  const _AiNote({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('stop-detail-ai-note'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppMetrics.padRowY,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        border: Border.all(
          color: AppColors.hairline,
          width: AppElevation.hairlineWidth,
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.xxs),
            child: AppIcon(
              LucideIcons.zap,
              size: AppMetrics.iconSm,
              color: AppColors.inkSubtle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              note,
              style: AppType.bodyApp.copyWith(color: AppColors.inkMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.skipped,
    required this.onSkip,
    required this.onNavigate,
  });

  final bool skipped;
  final VoidCallback onSkip;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('stop-detail-footer'),
      padding: const EdgeInsets.fromLTRB(
        AppMetrics.stopDetailContentPadding,
        AppMetrics.stopDetailFooterPaddingTop,
        AppMetrics.stopDetailContentPadding,
        AppMetrics.stopDetailFooterPaddingBottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        border: Border(
          top: BorderSide(
            color: AppColors.hairline,
            width: AppElevation.hairlineWidth,
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showNavigateIcon =
              constraints.maxWidth >=
              AppMetrics.stopDetailFooterIconMinimumWidth * 2 +
                  AppMetrics.stopDetailFooterGap;
          return Row(
            children: [
              Expanded(
                child: AppButton(
                  key: const ValueKey('stop-detail-skip'),
                  variant: AppButtonVariant.secondary,
                  fullWidth: true,
                  onPressed: onSkip,
                  child: Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(skipped ? 'Unskip' : 'Skip'),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppMetrics.stopDetailFooterGap),
              Expanded(
                child: AppButton(
                  key: const ValueKey('stop-detail-navigate'),
                  iconRight: showNavigateIcon ? LucideIcons.arrow_right : null,
                  fullWidth: true,
                  onPressed: onNavigate,
                  child: const Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Navigate'),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
