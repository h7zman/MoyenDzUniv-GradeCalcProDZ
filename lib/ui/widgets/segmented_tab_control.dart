import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class SegmentedTabControl extends StatefulWidget {
  const SegmentedTabControl({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
    this.onLongPress,
    this.scrollable = false,
  });

  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final ValueChanged<int>? onLongPress;
  final bool scrollable;

  @override
  State<SegmentedTabControl> createState() => _SegmentedTabControlState();
}

class _SegmentedTabControlState extends State<SegmentedTabControl> {
  late List<GlobalKey> _tabKeys;

  @override
  void initState() {
    super.initState();
    _tabKeys = List.generate(widget.tabs.length, (_) => GlobalKey());
    _scheduleEnsureVisible();
  }

  @override
  void didUpdateWidget(covariant SegmentedTabControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabs.length != widget.tabs.length) {
      _tabKeys = List.generate(widget.tabs.length, (_) => GlobalKey());
    }
    if (oldWidget.selectedIndex != widget.selectedIndex ||
        oldWidget.scrollable != widget.scrollable ||
        oldWidget.tabs.length != widget.tabs.length) {
      _scheduleEnsureVisible();
    }
  }

  void _scheduleEnsureVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.scrollable || widget.tabs.isEmpty) return;
      final safeIndex = widget.selectedIndex
          .clamp(0, widget.tabs.length - 1)
          .toInt();
      final targetContext = _tabKeys[safeIndex].currentContext;
      if (targetContext == null) return;

      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: 0.5,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);

    if (widget.tabs.isEmpty) return const SizedBox.shrink();

    if (widget.scrollable) {
      final safeIndex = widget.selectedIndex
          .clamp(0, widget.tabs.length - 1)
          .toInt();
      return Container(
        height: 56,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: tokens.chip,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: widget.tabs.length,
          addAutomaticKeepAlives: true,
          addRepaintBoundaries: true,
          separatorBuilder: (_, _) => const SizedBox(width: 4),
          itemBuilder: (context, index) {
            final selected = index == safeIndex;
            return InkWell(
              key: _tabKeys[index],
              borderRadius: BorderRadius.circular(12),
              onTap: () => widget.onChanged(index),
              onLongPress: widget.onLongPress == null
                  ? null
                  : () => widget.onLongPress!(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: selected
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            tokens.accent,
                            tokens.accent.withValues(alpha: 0.88),
                          ],
                        )
                      : null,
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: tokens.glow,
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 160),
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      color: selected
                          ? theme.colorScheme.onPrimary
                          : tokens.textMuted,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    child: Text(
                      widget.tabs[index],
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final safeIndex = widget.selectedIndex
            .clamp(0, widget.tabs.length - 1)
            .toInt();
        final tabWidth = constraints.maxWidth / widget.tabs.length;

        return Container(
          height: 56,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: tokens.chip,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                left: safeIndex * tabWidth,
                top: 0,
                bottom: 0,
                width: tabWidth,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          tokens.accent,
                          tokens.accent.withValues(alpha: 0.88),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: tokens.glow,
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: List.generate(widget.tabs.length, (index) {
                  final selected = index == safeIndex;
                  return Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => widget.onChanged(index),
                      onLongPress: widget.onLongPress == null
                          ? null
                          : () => widget.onLongPress!(index),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 180),
                          style: Theme.of(context).textTheme.titleMedium!
                              .copyWith(
                                color: selected
                                    ? theme.colorScheme.onPrimary
                                    : tokens.textMuted,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                          child: Text(
                            widget.tabs[index],
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}
