import 'package:flutter/widgets.dart';

import '../../core/theme/motion.dart';

/// Fades its child in and lets it rise [AppMotion.entranceRise] px into place the first
/// time it is built (`docs/PRD.md` D18).
///
/// [index] staggers a list: item n starts n × [AppMotion.entranceStagger] later, capped
/// at [AppMotion.entranceStaggerMaxItems] so a long list never waits. The delay is part
/// of the controller's timeline (an [Interval]), not a [Timer], so nothing is left
/// pending when the widget is disposed early. With the platform's reduce-motion setting
/// the child appears at once.
class Entrance extends StatefulWidget {
  const Entrance({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    final steps = widget.index.clamp(0, AppMotion.entranceStaggerMaxItems);
    final delay = AppMotion.entranceStagger * steps;
    final total = delay + AppMotion.entrance;
    _controller = AnimationController(vsync: this, duration: total);
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        delay.inMicroseconds / total.inMicroseconds,
        1,
        curve: AppMotion.easeEmphasized,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isAnimating || _controller.isCompleted) return;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _progress.value,
        child: Transform.translate(
          offset: Offset(0, (1 - _progress.value) * AppMotion.entranceRise),
          child: child,
        ),
      ),
    );
  }
}
