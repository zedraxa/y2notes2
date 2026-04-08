import 'package:flutter/material.dart';
import 'package:biscuits/app/theme/animation_curves.dart';
import 'package:biscuits/app/theme/elevation.dart';
import 'package:biscuits/app/theme/colors.dart';

/// Apple-style text field with smooth focus animations.
///
/// Features:
/// - Rounded corners matching iOS
/// - Smooth border color transitions
/// - Proper padding and spacing
/// - Clear button support
class AppleTextField extends StatefulWidget {
  const AppleTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.placeholder,
    this.prefix,
    this.suffix,
    this.showClearButton = false,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.enabled = true,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? placeholder;
  final Widget? prefix;
  final Widget? suffix;
  final bool showClearButton;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final int? maxLines;
  final bool enabled;

  @override
  State<AppleTextField> createState() => _AppleTextFieldState();
}

class _AppleTextFieldState extends State<AppleTextField> {
  late FocusNode _focusNode;
  late TextEditingController _controller;
  bool _isFocused = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _controller = widget.controller ?? TextEditingController();

    _focusNode.addListener(_onFocusChange);
    _controller.addListener(_onTextChange);

    _hasText = _controller.text.isNotEmpty;
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }

    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_onTextChange);
    }

    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _onTextChange() {
    setState(() {
      _hasText = _controller.text.isNotEmpty;
    });
  }

  void _clearText() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final fillColor = isDark
        ? AppColors.darkSurfaceVariant
        : AppColors.surfaceVariant;

    final borderColor = _isFocused
        ? (isDark ? AppColors.darkAccent : AppColors.accent)
        : Colors.transparent;

    return AnimatedContainer(
      duration: AppleDurations.quick,
      curve: AppleCurves.standard,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: AppleRadius.mdRadius,
        border: Border.all(
          color: borderColor,
          width: _isFocused ? 1.5 : 0,
        ),
      ),
      child: Row(
        children: [
          if (widget.prefix != null) ...[
            Padding(
              padding: const EdgeInsets.only(
                left: AppleSpacing.md,
                right: AppleSpacing.sm,
              ),
              child: widget.prefix!,
            ),
          ],
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              maxLines: widget.maxLines,
              style: TextStyle(
                fontSize: 17,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: widget.placeholder,
                hintStyle: TextStyle(
                  fontSize: 17,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppleSpacing.md,
                  vertical: AppleSpacing.md,
                ),
              ),
            ),
          ),
          if (widget.showClearButton && _hasText)
            AnimatedOpacity(
              duration: AppleDurations.quick,
              opacity: _hasText ? 1.0 : 0.0,
              child: GestureDetector(
                onTap: _clearText,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppleSpacing.sm,
                  ),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary)
                          .withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          if (widget.suffix != null) ...[
            Padding(
              padding: const EdgeInsets.only(
                left: AppleSpacing.sm,
                right: AppleSpacing.md,
              ),
              child: widget.suffix!,
            ),
          ],
        ],
      ),
    );
  }
}

/// Apple-style search field with magnifying glass icon.
class AppleSearchField extends StatelessWidget {
  const AppleSearchField({
    super.key,
    this.controller,
    this.focusNode,
    this.placeholder = 'Search',
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String placeholder;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppleTextField(
      controller: controller,
      focusNode: focusNode,
      placeholder: placeholder,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      showClearButton: true,
      textInputAction: TextInputAction.search,
      prefix: Icon(
        Icons.search_rounded,
        size: 20,
        color: isDark
            ? AppColors.darkTextSecondary
            : AppColors.textSecondary,
      ),
    );
  }
}
