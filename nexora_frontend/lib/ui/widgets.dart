import 'package:flutter/material.dart';
import 'theme.dart';

/// ── Nexora UI kit ─────────────────────────────────────────────────────────
/// Fully styled, theme-aware primitives shared by every screen, so all pages
/// get the same look from the same widgets.

/// Brand wordmark with the gradient chip + name, scalable.
class NxLogo extends StatelessWidget {
  const NxLogo({super.key, this.size = 40, this.showText = true, this.light = false});
  final double size;
  final bool showText;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final palette = nxOf(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: nxHeroGradient),
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          child: Center(
            child: Text(
              'N',
              style: TextStyle(
                color: palette.textOnAccent,
                fontSize: size * 0.55,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 12),
          Text(
            'Nexora',
            style: TextStyle(
              fontSize: size * 0.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
              color: light ? NxTheme.light.textPrimary : palette.textPrimary,
            ),
          ),
        ],
      ],
    );
  }
}

/// Circular / pill theme-mode toggle. Cycles light -> dark -> system.
class NxThemeToggle extends StatelessWidget {
  const NxThemeToggle({super.key, this.iconOnly = false});
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: nxThemeMode,
      builder: (context, mode, _) {
        final palette = nxOf(context);
        final label = nxThemeLabel(mode);
        if (iconOnly) {
          return _GhostIcon(
            icon: mode == ThemeMode.dark ? Icons.dark_mode_rounded : mode == ThemeMode.light ? Icons.light_mode_rounded : Icons.brightness_auto_rounded,
            tooltip: 'Theme: $label (tap to change)',
            onTap: () => nxThemeMode.value = nxNextTheme(mode),
          );
        }
        return Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: palette.surfaceAlt,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _GhostIcon(
                icon: mode == ThemeMode.dark ? Icons.dark_mode_rounded : mode == ThemeMode.light ? Icons.light_mode_rounded : Icons.brightness_auto_rounded,
                tooltip: 'Theme: $label (tap to change)',
                onTap: () => nxThemeMode.value = nxNextTheme(mode),
              ),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: palette.textMuted)),
              const SizedBox(width: 10),
            ],
          ),
        );
      },
    );
  }
}

/// ── Buttons ───────────────────────────────────────────────────────────────

class NxButton extends StatelessWidget {
  const NxButton({super.key, required this.label, this.onPressed, this.icon, this.variant = NxButtonVariant.primary, this.expanded = false, this.height = 48});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final NxButtonVariant variant;
  final bool expanded;
  final double height;

  @override
  Widget build(BuildContext context) {
    final palette = nxOf(context);
    final enabled = onPressed != null;

    Color bg;
    Color fg;
    Border? border;
    final onAccent = enabled ? palette.textOnAccent : palette.textMuted;
    switch (variant) {
      case NxButtonVariant.primary:
        bg = enabled ? palette.primary : palette.surfaceAlt;
        fg = onAccent;
      case NxButtonVariant.soft:
        bg = palette.primarySoft;
        fg = palette.primary;
      case NxButtonVariant.danger:
        bg = enabled ? palette.danger : palette.surfaceAlt;
        fg = onAccent;
      case NxButtonVariant.dangerSoft:
        bg = palette.danger.withOpacity(0.12);
        fg = palette.danger;
      case NxButtonVariant.success:
        bg = enabled ? palette.success : palette.surfaceAlt;
        fg = onAccent;
      case NxButtonVariant.ghost:
        bg = Colors.transparent;
        fg = palette.textMuted;
        border = Border.all(color: palette.border);
    }

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[Icon(icon, size: 18, color: fg), const SizedBox(width: 8)],
        Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: fg)),
      ],
    );

    return Material(
      color: enabled ? bg : palette.surfaceAlt,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: border),
          foregroundDecoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
          child: child,
        ),
      ),
    );
  }
}

enum NxButtonVariant { primary, soft, danger, dangerSoft, success, ghost }

/// Icon-only ghost button (headers, card actions).
class _GhostIcon extends StatelessWidget {
  const _GhostIcon({required this.icon, required this.tooltip, required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = nxOf(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 20, color: palette.textMuted),
          ),
        ),
      ),
    );
  }
}

/// Ghost round icon button whose color can be biased (e.g. red for delete).
class NxIconButton extends StatelessWidget {
  const NxIconButton({super.key, required this.icon, this.onTap, this.tooltip, this.color});
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = nxOf(context);
    return Tooltip(
      message: tooltip ?? icon.toString(),
      child: Material(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Icon(icon, size: 19, color: color ?? palette.textMuted),
          ),
        ),
      ),
    );
  }
}

/// ── Surfaces ──────────────────────────────────────────────────────────────

/// The base "card" of the redesign: flat surface, hairline border, soft shadow.
class NxCard extends StatelessWidget {
  const NxCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap, this.margin = EdgeInsets.zero});
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final palette = nxOf(context);
    return Padding(
      padding: margin,
      child: Material(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        shadowColor: palette.shadowColor,
        elevation: 1,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: palette.border),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Scaffold body scaffold: gradient background + padding, used by all pages.
class NxShell extends StatelessWidget {
  const NxShell({super.key, required this.child, this.padding = const EdgeInsets.all(20), this.scroll = true, this.bottomBar});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool scroll;
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    final palette = nxOf(context);
    final content = Padding(
      padding: padding,
      child: scroll ? SingleChildScrollView(child: child) : child,
    );
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: palette.isDark
              ? [const Color(0xFF0B0E17), const Color(0xFF0F1322)]
              : [const Color(0xFFF4F6FB), const Color(0xFFEDEFF6)],
        ),
      ),
      child: Column(
        children: [
          Expanded(child: scroll ? content : Padding(padding: padding, child: child)),
          if (bottomBar != null)
            Container(
              decoration: BoxDecoration(color: palette.surface, border: Border(top: BorderSide(color: palette.border))),
              child: SafeArea(top: false, child: bottomBar!),
            ),
        ],
      ),
    );
  }
}

/// Section title row, e.g. "SUPPLIERS   12 items".
class NxSectionHeader extends StatelessWidget {
  const NxSectionHeader({super.key, required this.title, this.trailing, this.subtitle});
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = nxOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: palette.textMuted)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: TextStyle(fontSize: 13, color: palette.textMuted)),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// ── Inputs ────────────────────────────────────────────────────────────────

class NxTextField extends StatelessWidget {
  const NxTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffix,
    this.obscure = false,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
    this.onChanged,
    this.enabled = true,
    this.maxLength,
    this.textInputAction,
    this.autofocus = false,
  });
  final TextEditingController controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final int? maxLength;
  final TextInputAction? textInputAction;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final palette = nxOf(context);
    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      maxLength: maxLength,
      enabled: enabled,
      onChanged: onChanged,
      textInputAction: textInputAction,
      style: TextStyle(color: palette.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20, color: palette.textMuted) : null,
        suffixIcon: suffix,
        filled: true,
        fillColor: palette.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: palette.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: palette.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: palette.primary, width: 1.4)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: palette.danger)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: palette.danger, width: 1.4)),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: palette.border)),
        labelStyle: TextStyle(color: palette.textMuted, fontSize: 14),
        hintStyle: TextStyle(color: palette.textMuted.withOpacity(0.7), fontSize: 14),
      ),
    );
  }
}

/// ── Data display ──────────────────────────────────────────────────────────

/// Small pill chip with semantic color variants.
class NxBadge extends StatelessWidget {
  const NxBadge({super.key, required this.text, this.variant = NxBadgeVariant.neutral, this.icon});
  final String text;
  final NxBadgeVariant variant;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = nxOf(context);
    final (color, bg) = switch (variant) {
      NxBadgeVariant.neutral => (palette.textMuted, palette.surfaceAlt),
      NxBadgeVariant.primary => (palette.primary, palette.primarySoft),
      NxBadgeVariant.success => (palette.success, palette.success.withOpacity(0.12)),
      NxBadgeVariant.warning => (palette.warning, palette.warning.withOpacity(0.12)),
      NxBadgeVariant.danger => (palette.danger, palette.danger.withOpacity(0.12)),
      NxBadgeVariant.info => (palette.info, palette.info.withOpacity(0.12)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: color), const SizedBox(width: 4)],
          Text(text, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

enum NxBadgeVariant { neutral, primary, success, warning, danger, info }

/// Map a raw API/status string to a semantic chip variant.
NxBadgeVariant nxStatusVariant(String raw) {
  final s = raw.toLowerCase();
  if (s.contains('receive') || s.contains('paid') || s.contains('success') || s.contains('active') || s.contains('completed')) return NxBadgeVariant.success;
  if (s.contains('draft') || s.contains('pending') || s.contains('submit')) return NxBadgeVariant.neutral;
  if (s.contains('cancel') || s.contains('fail')) return NxBadgeVariant.danger;
  if (s.contains('part') || s.contains('ship')) return NxBadgeVariant.info;
  return NxBadgeVariant.primary;
}

/// Big rounded icon block (48px) behind accents/tiles.
class NxIconBlock extends StatelessWidget {
  const NxIconBlock({super.key, required this.icon, required this.color, this.size = 52});
  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color.withOpacity(0.13), borderRadius: BorderRadius.circular(16)),
      child: Center(child: Icon(icon, color: color, size: size * 0.5)),
    );
  }
}

/// Friendly empty state with icon, message and optional action.
class NxEmptyState extends StatelessWidget {
  const NxEmptyState({super.key, required this.icon, required this.title, this.message, this.actionLabel, this.onAction});
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final palette = nxOf(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(color: palette.surface, shape: BoxShape.circle, border: Border.all(color: palette.border)),
            child: Icon(icon, size: 36, color: palette.textMuted),
          ),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: palette.textPrimary)),
          if (message != null) ...[
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Text(message!, textAlign: TextAlign.center, style: TextStyle(fontSize: 13.5, color: palette.textMuted)),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            NxButton(label: actionLabel!, icon: Icons.add_rounded, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}

/// Centered error state with retry.
class NxErrorView extends StatelessWidget {
  const NxErrorView({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return NxEmptyState(
      icon: Icons.cloud_off_rounded,
      title: 'Something went wrong',
      message: message.replaceAll('Exception: ', ''),
      actionLabel: onRetry != null ? 'Try again' : null,
      onAction: onRetry,
    );
  }
}

/// Thick rounded progress indicator in brand color.
class NxLoader extends StatelessWidget {
  const NxLoader({super.key, this.label});
  final String? label;

  @override
  Widget build(BuildContext context) {
    final palette = nxOf(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 3, color: palette.primary),
          ),
          if (label != null) ...[
            const SizedBox(height: 12),
            Text(label!, style: TextStyle(fontSize: 13, color: palette.textMuted)),
          ],
        ],
      ),
    );
  }
}

/// ── Page scaffolding ──────────────────────────────────────────────────────

/// Page header used instead of AppBar: title, subtitle, back, actions.
/// Chosen over NxLogo for inner pages.
class NxHeader extends StatelessWidget {
  const NxHeader({super.key, required this.title, this.subtitle, this.leading, this.actions = const []});
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final palette = nxOf(context);
    return Row(
      children: [
        if (leading != null) leading!,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: palette.textPrimary, letterSpacing: -0.3),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: palette.textMuted)),
              ],
            ],
          ),
        ),
        ...actions,
      ],
    );
  }
}

/// Back button used inside NxHeader.leading.
class NxBackButton extends StatelessWidget {
  const NxBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = nxOf(context);
    return NxIconButton(
      icon: Icons.arrow_back_rounded,
      tooltip: 'Back',
      onTap: () => Navigator.maybePop(context),
      color: palette.textPrimary,
    );
  }
}

/// ── Dialogs & snackbars ───────────────────────────────────────────────────

/// Themed dialog shell — always use this instead of raw AlertDialog.
Widget nxDialog({required BuildContext context, required String title, required Widget content, List<Widget> actions = const [], Widget? leadingIcon}) {
  final palette = nxOf(context);
  return AlertDialog(
    backgroundColor: palette.surface,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: BorderSide(color: palette.border)),
    titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
    contentPadding: const EdgeInsets.fromLTRB(24, 14, 24, 8),
    actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    title: Row(
      children: [
        if (leadingIcon != null) ...[leadingIcon, const SizedBox(width: 10)],
        Expanded(
          child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: palette.textPrimary)),
        ),
      ],
    ),
    content: IntrinsicWidth(child: content),
    actions: [
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [for (final a in actions) ...[a, const SizedBox(width: 10)]],
      ),
    ],
  );
}

/// Confirmation dialog → true when confirmed.
Future<bool> nxConfirm(BuildContext context, {required String title, required String message, String confirmLabel = 'Confirm', NxButtonVariant variant = NxButtonVariant.primary}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => nxDialog(
      context: dialogContext,
      title: title,
      actions: [
        NxButton(label: 'Cancel', variant: NxButtonVariant.ghost, onPressed: () => Navigator.pop(dialogContext, false)),
        NxButton(label: confirmLabel, variant: variant, onPressed: () => Navigator.pop(dialogContext, true)),
      ],
      content: Text(message, style: const TextStyle(fontSize: 14.5, height: 1.4)),
    ),
  );
  return result ?? false;
}

/// Consistent snackbar content helper.
void nxSnack(BuildContext context, String message, {bool isError = false}) {  final palette = nxOf(context);
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: palette.isDark ? const Color(0xFF1C2137) : const Color(0xFF171C2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      duration: const Duration(seconds: 3),
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: isError ? palette.danger : palette.success,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 13.5),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Theme-styled switch row used inside dialogs and cards.
class NxSwitchRow extends StatelessWidget {
  const NxSwitchRow({super.key, required this.title, required this.subtitle, required this.value, required this.onToggle});
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final palette = nxOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: palette.textPrimary)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: palette.textMuted)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => onToggle(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 44,
              height: 26,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: value ? palette.primary : palette.border,
                borderRadius: BorderRadius.circular(999),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 180),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
