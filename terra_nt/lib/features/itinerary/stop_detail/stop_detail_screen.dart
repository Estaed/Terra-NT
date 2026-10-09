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
import '../../../core/util/itinerary_ops.dart';
import '../../../core/util/maps_url.dart';
import '../../../core/util/tag_colors.dart';
import '../../../data/models/plan_entry.dart';
import '../../../data/models/stop.dart';
import '../../../data/repositories/notifiers.dart';
import '../../../data/seed/place_images.dart';
import '../../../shared/widgets/app_icon.dart';
import '../../../shared/widgets/entrance.dart';
import '../../../shared/widgets/tag_dot.dart';
import '../widgets/result_stop_list.dart' show StopPicture, MapsLaunchFailure;

typedef StopMapsLauncher = Future<bool> Function(Uri url);

/// Details for one itinerary stop, pushed above the Plan AI stack.
class StopDetailScreen extends ConsumerStatefulWidget {
  const StopDetailScreen({
    super.key,
    required this.stop,
    required this.originalIndex,
    this.launcher = launchUrl,
  });

  final Stop stop;
  final int originalIndex;
  final StopMapsLauncher launcher;

  @override
  ConsumerState<StopDetailScreen> createState() => _StopDetailScreenState();
}

class _StopDetailScreenState extends ConsumerState<StopDetailScreen> {
  bool _launchFailed = false;
  bool _roadLaunchFailed = false;

  void _goBack(BuildContext context) {
    Navigator.of(context).pop();
  }

  void _toggleSkip(BuildContext context) {
    HapticFeedback.lightImpact();
    ref
        .read(itineraryNotifierProvider.notifier)
        .toggleSkipped(widget.originalIndex);
    _goBack(context);
  }

  Future<void> _navigate() async {
    final url = singleDestinationUrl(widget.stop);
    if (url == null) return;
    var opened = false;
    try {
      opened = await widget.launcher(Uri.parse(url));
    } catch (_) {
      // A missing maps app or platform failure should offer coordinates too.
    }
    if (mounted) setState(() => _launchFailed = !opened);
  }

  Future<void> _checkRoadConditions() async {
    var opened = false;
    try {
      opened = await widget.launcher(
        Uri.parse('https://nt.gov.au/driving/safety/check-road-conditions'),
      );
    } catch (_) {
      // Keep the link available so the traveller can try again.
    }
    if (mounted) setState(() => _roadLaunchFailed = !opened);
  }

  @override
  Widget build(BuildContext context) {
    final stop = widget.stop;
    final originalIndex = widget.originalIndex;
    final itineraryState = ref.watch(itineraryNotifierProvider);
    final skipped = itineraryState.skipped.contains(originalIndex);
    final driveNext = driveNextForPosition(
      itineraryState.order,
      itineraryState.order.indexOf(originalIndex),
      itineraryState.itinerary.stops,
      skipped: itineraryState.skipped,
    );

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
                          : _DetailPlan(
                              key: const ValueKey('stop-detail-plan'),
                              entries: stop.detailedPlan,
                            ),
                    ),
                    const SizedBox(height: AppMetrics.stopDetailContentGap),
                    Entrance(index: 3, child: _TagList(tags: stop.tags)),
                    const SizedBox(height: AppMetrics.stopDetailContentGap),
                    Entrance(
                      index: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _InfoCard(stop: stop),
                          if (driveNext != null) ...[
                            const SizedBox(
                              height: AppMetrics.stopDetailContentGap,
                            ),
                            _InfoRow(
                              label: 'Next active stop',
                              value: driveNext,
                            ),
                          ],
                          TextButton(
                            key: const ValueKey('stop-detail-road-conditions'),
                            onPressed: _checkRoadConditions,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              minimumSize: const Size(
                                AppMetrics.minTouchTarget,
                                AppMetrics.minTouchTarget,
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.xs,
                              ),
                              alignment: Alignment.centerLeft,
                              textStyle: AppType.buttonApp,
                            ),
                            child: const Text('Check road conditions'),
                          ),
                          Text(
                            'An internet connection is needed.',
                            style: AppType.bodySm.copyWith(
                              color: AppColors.inkSubtle,
                            ),
                          ),
                          if (_roadLaunchFailed)
                            Text(
                              'Road conditions could not be opened. Check your connection and try again.',
                              style: AppType.bodySm.copyWith(
                                color: AppColors.inkSubtle,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppMetrics.stopDetailContentGap),
                    Entrance(index: 5, child: _AiNote(note: stop.aiNote)),
                  ],
                ),
              ),
            ),
            _Footer(
              skipped: skipped,
              onSkip: () => _toggleSkip(context),
              onNavigate: _navigate,
              failureCoordinates: _launchFailed
                  ? destinationCoordinates(stop)
                  : null,
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
            fallbackImage: placeImageFor(stop.name, tags: stop.tags),
          ),
          Positioned(
            // The hero stays full-bleed under the status bar; the only control
            // on top of it does not.
            top: AppSpacing.md + MediaQuery.viewPaddingOf(context).top,
            left: AppSpacing.md,
            child: Semantics(
              label: 'Back',
              button: true,
              onTap: onBack,
              excludeSemantics: true,
              child: GestureDetector(
                excludeFromSemantics: true,
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

/// The time column grows to its longest entry at the system text size.
/// Activities use the remaining width; times never wrap within a token.
class _DetailPlan extends StatelessWidget {
  const _DetailPlan({super.key, required this.entries});

  final List<PlanEntry> entries;

  @override
  Widget build(BuildContext context) {
    final timeStyle = AppType.captionApp.copyWith(
      color: AppColors.inkTertiary,
      fontFamily: AppFonts.mono,
    );
    return Table(
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: FixedColumnWidth(AppMetrics.resultStopListGap),
        2: FlexColumnWidth(),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.top,
      children: [
        for (final entry in entries)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  bottom: AppMetrics.resultStopEditActionGap,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: AppMetrics.resultStopPlanTimeWidth,
                  ),
                  child: Text(
                    entry.time,
                    softWrap: false,
                    maxLines: 1,
                    style: timeStyle,
                  ),
                ),
              ),
              const SizedBox.shrink(),
              Padding(
                padding: const EdgeInsets.only(
                  bottom: AppMetrics.resultStopEditActionGap,
                ),
                child: Text(
                  entry.activity,
                  style: AppType.bodyApp.copyWith(color: AppColors.inkMuted),
                ),
              ),
            ],
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
          _InfoRow(label: 'Hours', value: stop.hours, icon: LucideIcons.clock),
          if (stop.fee != null) ...[
            const SizedBox(height: AppMetrics.stopDetailInfoGap),
            Container(
              height: AppElevation.hairlineWidth,
              color: AppColors.hairline,
            ),
            const SizedBox(height: AppMetrics.stopDetailInfoGap),
            _InfoRow(
              label: 'Park entry fee',
              value: stop.fee!,
              icon: LucideIcons.ticket,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.icon});

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                label,
                style: AppType.bodySm.copyWith(color: AppColors.inkSubtle),
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: AppSpacing.xs),
              AppIcon(
                icon!,
                size: AppMetrics.iconMd,
                color: AppColors.inkSubtle,
              ),
            ],
          ],
        ),
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
    required this.failureCoordinates,
  });

  final bool skipped;
  final VoidCallback onSkip;
  final VoidCallback onNavigate;
  final String? failureCoordinates;

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
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (failureCoordinates != null) ...[
                MapsLaunchFailure(coordinates: failureCoordinates!),
                const SizedBox(height: AppSpacing.xs),
              ],
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      key: const ValueKey('stop-detail-skip'),
                      onPressed: onSkip,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.actionSecondaryFg,
                        backgroundColor: AppColors.actionSecondaryBg,
                        minimumSize: const Size(
                          AppMetrics.minTouchTarget,
                          AppMetrics.minTouchTarget,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.padButtonX,
                          vertical: AppSpacing.padButtonY,
                        ),
                        textStyle: AppType.button,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.button),
                          side: const BorderSide(
                            color: AppColors.borderCard,
                            width: AppElevation.hairlineWidth,
                          ),
                        ),
                      ),
                      child: Text(
                        skipped ? 'Unskip' : 'Skip',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppMetrics.stopDetailFooterGap),
                  Expanded(
                    child: TextButton(
                      key: const ValueKey('stop-detail-navigate'),
                      onPressed: onNavigate,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.actionPrimaryFg,
                        backgroundColor: AppColors.actionPrimaryBg,
                        minimumSize: const Size(
                          AppMetrics.minTouchTarget,
                          AppMetrics.minTouchTarget,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.padButtonX,
                          vertical: AppSpacing.padButtonY,
                        ),
                        textStyle: AppType.button,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.button),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Navigate',
                              textAlign: TextAlign.center,
                            ),
                          ),
                          if (showNavigateIcon) ...[
                            const SizedBox(width: AppMetrics.gapButtonIcon),
                            const AppIcon(
                              LucideIcons.arrow_right,
                              size: AppMetrics.iconMd,
                              color: AppColors.actionPrimaryFg,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
