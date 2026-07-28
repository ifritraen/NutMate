import 'package:flutter/material.dart';
import 'glass_card.dart';

class FloatingTopBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool isVisible;

  const FloatingTopBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedSlide(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      offset: isVisible ? Offset.zero : const Offset(0, -1.5),
      child: SafeArea(
        bottom: false,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            borderRadius: BorderRadius.circular(14),
            child: IconTheme(
              data: const IconThemeData(size: 20),
              child: Row(
                children: [
                  if (leading != null) leading!,
                  if (leading != null) const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (actions != null) ...actions!,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
