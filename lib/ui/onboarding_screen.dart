import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _floatController;

  int _currentPage = 0;

  final _pages = const <_OnboardingPageData>[
    _OnboardingPageData(
      titleTop: 'Set Custom',
      titleAccent: 'Coefficients',
      description:
          'Customize how much each module counts towards your final grade. We calculate weighted averages based on official university standards.',
      cta: 'Next',
      mood: _OnboardingMood.coeff,
    ),
    _OnboardingPageData(
      titleTop: 'Easily Add',
      titleAccent: 'Your Modules',
      description:
          'Track your performance effortlessly. Add your modules, assign coefficients, and let us handle the math.',
      cta: 'Next',
      mood: _OnboardingMood.modules,
    ),
    _OnboardingPageData(
      titleTop: 'Track Your',
      titleAccent: 'Progress',
      description:
          'Watch your dynamic stats, module averages, and final result update in real time as you enter your grades.',
      cta: 'Get Started',
      mood: _OnboardingMood.progress,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage >= _pages.length - 1) {
      widget.onComplete();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [tokens.bgTop, tokens.bgBottom],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _PaperTexturePainter(
                  color: theme.colorScheme.onSurface.withValues(
                    alpha: theme.brightness == Brightness.dark ? 0.05 : 0.08,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _currentPage == 0
                              ? null
                              : () => _pageController.previousPage(
                                  duration: const Duration(milliseconds: 280),
                                  curve: Curves.easeOutCubic,
                                ),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: widget.onComplete,
                          child: Text(
                            'Skip',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: tokens.accentAlt,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _pages.length,
                      allowImplicitScrolling: true,
                      onPageChanged: (index) =>
                          setState(() => _currentPage = index),
                      itemBuilder: (context, index) {
                        return _OnboardingPage(
                          data: _pages[index],
                          isActive: index == _currentPage,
                          floatAnimation: _floatController,
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_pages.length, (index) {
                            final selected = index == _currentPage;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 260),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: selected ? 34 : 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: selected
                                    ? tokens.accentAlt
                                    : tokens.accentAlt.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.12,
                                  ),
                                ),
                                boxShadow: selected
                                    ? [
                                        BoxShadow(
                                          color: tokens.accentAlt.withValues(
                                            alpha: 0.32,
                                          ),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 18),
                        _PaperPrimaryButton(
                          label: _pages[_currentPage].cta,
                          onPressed: _next,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaperPrimaryButton extends StatefulWidget {
  const _PaperPrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  State<_PaperPrimaryButton> createState() => _PaperPrimaryButtonState();
}

class _PaperPrimaryButtonState extends State<_PaperPrimaryButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSurface.withValues(alpha: 0.72);

    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          height: 62,
          width: double.infinity,
          transform: Matrix4.translationValues(
            _pressed ? 4 : 0,
            _pressed ? 4 : 0,
            0,
          ),
          decoration: BoxDecoration(
            color: tokens.accentAlt,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: ink, width: 1.5),
            boxShadow: _pressed
                ? const []
                : [
                    BoxShadow(
                      color: ink,
                      blurRadius: 0,
                      offset: const Offset(4, 4),
                    ),
                  ],
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF081122),
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF081122),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MarkerAccentText extends StatelessWidget {
  const _MarkerAccentText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Positioned(
          left: 2,
          right: 2,
          bottom: 4,
          height: 16,
          child: CustomPaint(
            painter: _MarkerHighlightPainter(
              color: tokens.accentAlt.withValues(alpha: 0.3),
            ),
          ),
        ),
        Text(
          text,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: tokens.accentAlt,
          ),
        ),
      ],
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.data,
    required this.isActive,
    required this.floatAnimation,
  });

  final _OnboardingPageData data;
  final bool isActive;
  final Animation<double> floatAnimation;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Expanded(
            child: AnimatedBuilder(
              animation: floatAnimation,
              builder: (context, child) {
                final y = math.sin(floatAnimation.value * math.pi * 2) * 8;
                return Transform.translate(offset: Offset(0, y), child: child);
              },
              child: _OnboardingIllustration(mood: data.mood),
            ),
          ),
          const SizedBox(height: 14),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 240),
            opacity: isActive ? 1 : 0.35,
            child: Column(
              children: [
                Text(
                  data.titleTop,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                _MarkerAccentText(text: data.titleAccent),
                const SizedBox(height: 12),
                Text(
                  data.description,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: tokens.textMuted,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'By H7Z man',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: tokens.textMuted.withValues(alpha: 0.62),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _OnboardingIllustration extends StatelessWidget {
  const _OnboardingIllustration({required this.mood});

  final _OnboardingMood mood;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final isCompact = MediaQuery.sizeOf(context).height < 700;
    final panelSize = isCompact ? 232.0 : 292.0;
    final glowSize = isCompact ? 260.0 : 320.0;
    final panelPadding = isCompact ? 12.0 : 18.0;
    final rotation = switch (mood) {
      _OnboardingMood.coeff => -0.012,
      _OnboardingMood.modules => 0.01,
      _OnboardingMood.progress => -0.006,
    };

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: glowSize,
          height: glowSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                tokens.accentAlt.withValues(alpha: 0.2),
                tokens.accentAlt.withValues(alpha: 0.03),
                Colors.transparent,
              ],
            ),
          ),
        ),
        _PaperCard(
          width: panelSize,
          height: panelSize,
          padding: EdgeInsets.all(panelPadding),
          rotation: rotation,
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: 300,
              height: 300,
              child: _moodContent(theme, tokens),
            ),
          ),
        ),
      ],
    );
  }

  Widget _moodContent(ThemeData theme, AppThemeTokens tokens) {
    switch (mood) {
      case _OnboardingMood.coeff:
        return Column(
          children: [
            _fakeBar(width: 120),
            const SizedBox(height: 18),
            _listRow(tokens, theme, highlighted: false),
            const SizedBox(height: 12),
            _listRow(tokens, theme, highlighted: true),
            const SizedBox(height: 12),
            _listRow(tokens, theme, highlighted: false),
            const Spacer(),
            Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: tokens.cardAlt,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: tokens.shadow.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Text(
                  'x Weight',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF50647F),
                  ),
                ),
              ),
            ),
          ],
        );
      case _OnboardingMood.modules:
        return Column(
          children: [
            const Spacer(),
            Icon(Icons.checklist_rounded, size: 88, color: tokens.accentAlt),
            const SizedBox(height: 12),
            Text(
              'Add modules quickly',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            _fakeChecklist(tokens),
            const Spacer(),
          ],
        );
      case _OnboardingMood.progress:
        return Column(
          children: [
            const SizedBox(height: 10),
            Text(
              'LIVE STATS',
              style: theme.textTheme.labelLarge?.copyWith(
                color: tokens.textMuted,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 150,
                  height: 150,
                  child: CustomPaint(
                    painter: _MiniRingPainter(
                      color: tokens.accent,
                      track: tokens.chip,
                    ),
                    child: Center(
                      child: Text(
                        '14.8',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0D172A),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _fakeBar(width: 170),
            const SizedBox(height: 10),
            _fakeBar(width: 130),
            const SizedBox(height: 20),
          ],
        );
    }
  }

  Widget _fakeChecklist(AppThemeTokens tokens) {
    return Column(
      children: List.generate(3, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: index < 2
                    ? tokens.accentAlt
                    : tokens.textMuted.withValues(alpha: 0.45),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: index < 2
                        ? tokens.accentAlt.withValues(alpha: 0.25)
                        : tokens.chip,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _listRow(
    AppThemeTokens tokens,
    ThemeData theme, {
    required bool highlighted,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: highlighted
            ? tokens.accentAlt.withValues(alpha: 0.12)
            : tokens.cardAlt,
        borderRadius: BorderRadius.circular(16),
        border: highlighted
            ? Border.all(color: tokens.accentAlt.withValues(alpha: 0.55))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: highlighted ? tokens.accentAlt : tokens.chip,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(
              Icons.percent_rounded,
              color: highlighted ? const Color(0xFF071324) : tokens.textMuted,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: _fakeBar(width: 130)),
          const SizedBox(width: 8),
          Text(
            highlighted ? '3.0' : '--',
            style: theme.textTheme.titleMedium?.copyWith(
              color: highlighted ? tokens.accentAlt : tokens.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fakeBar({required double width}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: width,
        height: 11,
        decoration: BoxDecoration(
          color: const Color(0xFFCFD6E2),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _PaperCard extends StatelessWidget {
  const _PaperCard({
    required this.width,
    required this.height,
    required this.padding,
    required this.rotation,
    required this.child,
  });

  final double width;
  final double height;
  final EdgeInsets padding;
  final double rotation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final edge = theme.colorScheme.onSurface.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.55 : 0.5,
    );
    final paperColor = Color.lerp(tokens.card, const Color(0xFFFBF9F4), 0.58)!;

    return Transform.rotate(
      angle: rotation,
      child: SizedBox(
        width: width + 10,
        height: height + 10,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 9,
              top: 9,
              child: Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: edge,
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
            ),
            Container(
              width: width,
              height: height,
              padding: padding,
              decoration: BoxDecoration(
                color: paperColor,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: edge, width: 1.6),
                boxShadow: [
                  BoxShadow(
                    color: tokens.shadow.withValues(alpha: 0.2),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _PaperTexturePainter(
                          color: edge.withValues(alpha: 0.08),
                          spacing: 18,
                        ),
                      ),
                    ),
                    child,
                  ],
                ),
              ),
            ),
            Positioned(
              top: -8,
              left: width * 0.18,
              child: Transform.rotate(
                angle: -0.07,
                child: Container(
                  width: 70,
                  height: 22,
                  decoration: BoxDecoration(
                    color: tokens.accentAlt.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: edge.withValues(alpha: 0.28)),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 18,
              bottom: 14,
              child: CustomPaint(
                size: const Size(36, 22),
                painter: _DoodleSparkPainter(color: tokens.accentAlt),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniRingPainter extends CustomPainter {
  _MiniRingPainter({required this.color, required this.track});

  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    final activePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * 0.74, false, activePaint);
  }

  @override
  bool shouldRepaint(covariant _MiniRingPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.track != track;
  }
}

class _PaperTexturePainter extends CustomPainter {
  const _PaperTexturePainter({required this.color, this.spacing = 24});

  final Color color;
  final double spacing;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (var y = 0.0; y < size.height; y += spacing) {
      for (var x = 0.0; x < size.width; x += spacing) {
        final wobble = math.sin(x * 0.31 + y * 0.17) * 1.4;
        canvas.drawCircle(Offset(x + wobble, y - wobble), 0.65, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PaperTexturePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.spacing != spacing;
  }
}

class _MarkerHighlightPainter extends CustomPainter {
  const _MarkerHighlightPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, size.height * 0.42)
      ..quadraticBezierTo(
        size.width * 0.28,
        size.height * 0.12,
        size.width * 0.52,
        size.height * 0.34,
      )
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.56,
        size.width,
        size.height * 0.28,
      )
      ..lineTo(size.width, size.height * 0.92)
      ..quadraticBezierTo(size.width * 0.52, size.height, 0, size.height * 0.86)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MarkerHighlightPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _DoodleSparkPainter extends CustomPainter {
  const _DoodleSparkPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.5),
      Offset(size.width * 0.36, size.height * 0.5),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.66, size.height * 0.2),
      Offset(size.width * 0.88, size.height * 0.02),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.66, size.height * 0.8),
      Offset(size.width * 0.9, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _DoodleSparkPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.titleTop,
    required this.titleAccent,
    required this.description,
    required this.cta,
    required this.mood,
  });

  final String titleTop;
  final String titleAccent;
  final String description;
  final String cta;
  final _OnboardingMood mood;
}

enum _OnboardingMood { coeff, modules, progress }
