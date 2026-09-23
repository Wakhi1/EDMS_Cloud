import 'package:flutter/material.dart';

import '../theme/pspf_tokens.dart';

/// Shared dense building blocks for list/management screens (Reports, Audit,
/// Settings…): a two-line page header, and 30px-high filter controls that
/// line up with each other.

/// Title with a small breadcrumb underneath, actions on the right.
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.breadcrumb, this.actions = const []});

  final String title;
  final String? breadcrumb;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              if (breadcrumb != null) Text(breadcrumb!, style: TextStyle(fontSize: 11, color: tokens.ink3)),
            ],
          ),
        ),
        for (var i = 0; i < actions.length; i++) ...[if (i > 0) const SizedBox(width: 8), actions[i]],
      ],
    );
  }
}

/// 30px bordered dropdown with an optional inline label.
class CompactSelect<T> extends StatelessWidget {
  const CompactSelect({super.key, required this.value, required this.items, required this.onChanged, this.label, this.hint, this.width});

  final T value;
  final List<(T, String)> items;
  final ValueChanged<T?>? onChanged;
  final String? label;
  final String? hint;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final hasValue = items.any((i) => i.$1 == value);
    return Container(
      width: width,
      height: 30,
      padding: const EdgeInsets.only(left: 8, right: 4),
      decoration: BoxDecoration(color: tokens.surf, border: Border.all(color: tokens.line2)),
      child: Row(
        children: [
          if (label != null) ...[Text(label!, style: TextStyle(fontSize: 11, color: tokens.ink3)), const SizedBox(width: 6)],
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: hasValue ? value : null,
                isExpanded: true,
                isDense: true,
                iconSize: 18,
                hint: Text(hint ?? 'All', style: TextStyle(fontSize: 12, color: tokens.ink3)),
                style: (Theme.of(context).textTheme.bodyMedium ?? const TextStyle()).copyWith(fontSize: 12, color: tokens.ink),
                items: [for (final (v, text) in items) DropdownMenuItem<T>(value: v, child: Text(text, overflow: TextOverflow.ellipsis))],
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 30px outlined button with an optional leading icon; [busy] shows a spinner.
class CompactButton extends StatelessWidget {
  const CompactButton({super.key, required this.label, required this.onPressed, this.icon, this.busy = false, this.primary = false});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final fg = primary ? Colors.white : tokens.ink;
    return InkWell(
      onTap: busy ? null : onPressed,
      child: Opacity(
        opacity: onPressed == null ? 0.5 : 1,
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(color: primary ? tokens.acc : tokens.surf, border: Border.all(color: primary ? tokens.acc : tokens.line2)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy)
                SizedBox(width: 13, height: 13, child: CircularProgressIndicator(strokeWidth: 2, color: fg))
              else if (icon != null)
                Icon(icon, size: 15, color: fg),
              if (busy || icon != null) const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 12, color: fg, fontWeight: primary ? FontWeight.w600 : FontWeight.w400)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 30px search box that submits on Enter.
class CompactSearchField extends StatelessWidget {
  const CompactSearchField({super.key, required this.controller, required this.onSubmitted, this.hint = 'Search…', this.width = 220});

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final String hint;
  final double width;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return SizedBox(
      width: width,
      height: 30,
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 12),
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: tokens.surf,
          hintText: hint,
          hintStyle: TextStyle(fontSize: 12, color: tokens.ink3),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          prefixIcon: Icon(Icons.search, size: 15, color: tokens.ink3),
          prefixIconConstraints: const BoxConstraints(minWidth: 30),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: tokens.line2)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: tokens.accD)),
        ),
        onSubmitted: onSubmitted,
      ),
    );
  }
}
