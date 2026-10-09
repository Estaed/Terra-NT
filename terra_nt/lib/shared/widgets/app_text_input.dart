import 'package:flutter/material.dart' show TextField, InputDecoration, InputBorder;
import 'package:flutter/widgets.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/elevation.dart';
import '../../core/theme/radius.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';

/// The prototype's `TextInput` component (`_ds_bundle.js`, not in the repo).
///
/// Reconstructed from Task-01's tokens; the label styling is itself a reconstruction
/// — the bundle is missing, and the prototype's only evidence is a
/// `hint-size="100%,60px"` budget for label + gap + field (`docs/PRD.md` §2, gap 3).
///
/// `errorText == null` renders no error copy or invalid-field colour treatment:
/// `docs/PRD.md` Q5 is unanswered, and Task-09 owns both once it is.
class AppTextInput extends StatefulWidget {
  const AppTextInput({
    super.key,
    required this.label,
    this.placeholder,
    this.errorText,
    this.obscureText = false,
    this.controller,
    this.onChanged,
    this.keyboardType,
  });

  final String label;
  final String? placeholder;
  final String? errorText;
  final bool obscureText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;

  @override
  State<AppTextInput> createState() => _AppTextInputState();
}

class _AppTextInputState extends State<AppTextInput> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_onFocusChange);
  }

  void _onFocusChange() => setState(() {});

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChange)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focusNode.hasFocus;

    // The `TextField` is only as tall as one line of text (24px), so the
    // decorated box's own padding — and the label above it — used to swallow a
    // tap without focusing anything. Making the whole control focus the field
    // is what a label paired with an input has always done, and it gives the
    // control a hit target the size of the whole column — already past the
    // minimum touch target — without moving a painted pixel.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _focusNode.requestFocus,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.label,
            style: AppType.caption.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.padInputX,
              vertical: AppSpacing.padInputY,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface1,
              borderRadius: BorderRadius.circular(AppRadius.input),
              border: Border.all(
                color: focused
                    ? AppElevation.ringFocusColor
                    : AppColors.borderCard,
                width: focused
                    ? AppElevation.ringFocusWidth
                    : AppElevation.hairlineWidth,
              ),
            ),
            child: TextField(
              focusNode: _focusNode,
              controller: widget.controller,
              onChanged: widget.onChanged,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              style: AppType.body.copyWith(color: AppColors.textBody),
              decoration: InputDecoration(
                hintText: widget.placeholder,
                hintStyle: AppType.body.copyWith(color: AppColors.textTertiary),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (widget.errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxs),
              child: Text(
                widget.errorText!,
                style: AppType.caption.copyWith(color: AppColors.tagRed),
              ),
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}
