import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'l10n/app_localizations.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'ui/home_page.dart';
import 'ui/onboarding_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GradeCalcApp());
}

class GradeCalcApp extends StatefulWidget {
  const GradeCalcApp({super.key});

  @override
  State<GradeCalcApp> createState() => _GradeCalcAppState();
}

class _GradeCalcAppState extends State<GradeCalcApp>
    with WidgetsBindingObserver {
  late final AppState _state;
  final GlobalKey _repaintKey = GlobalKey();

  int _displayedThemeIndex = 0;
  int _displayedRevealKey = 0;
  Offset? _displayedRevealOrigin;

  ui.Image? _previousFrameImage;
  double _previousFrameScale = 1;
  bool _capturingThemeFrame = false;
  bool _pendingThemeSync = false;

  bool _prefsLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _enableImmersiveMode();

    _state = AppState.seeded();
    _displayedThemeIndex = _state.themeIndex;
    _displayedRevealKey = _state.themeRevealSerial;
    _displayedRevealOrigin = _state.themeRevealOrigin;
    _state.themeChanges.addListener(_onThemeChanged);
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    await _state.loadFromPrefs(maxThemes: AppThemes.choices.length);
    if (mounted) {
      setState(() => _prefsLoaded = true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _enableImmersiveMode();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _state.themeChanges.removeListener(_onThemeChanged);
    _disposePreviousFrameImage();
    _state.dispose();
    super.dispose();
  }

  Future<void> _enableImmersiveMode() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _onThemeChanged() async {
    if (!mounted) {
      return;
    }

    final nextThemeIndex = _state.themeIndex.clamp(
      0,
      AppThemes.choices.length - 1,
    );
    final nextRevealKey = _state.themeRevealSerial;
    final nextRevealOrigin = _state.themeRevealOrigin;

    // In release builds, prefer reliability over frame capture transitions.
    // Some GPU/device combinations can fail to produce a stable `toImage`
    // snapshot, which may block visual theme updates.
    if (kReleaseMode) {
      setState(() {
        _disposePreviousFrameImage();
        _displayedThemeIndex = nextThemeIndex;
        _displayedRevealKey = nextRevealKey;
        _displayedRevealOrigin = nextRevealOrigin;
      });
      return;
    }

    if (_capturingThemeFrame) {
      _pendingThemeSync = true;
      return;
    }

    _capturingThemeFrame = true;
    try {
      ui.Image? captured;
      var capturedScale = 1.0;
      final repaintContext = _repaintKey.currentContext;
      if (repaintContext != null) {
        final render = repaintContext.findRenderObject();
        if (render is RenderRepaintBoundary &&
            render.hasSize &&
            !render.debugNeedsPaint) {
          try {
            capturedScale = View.of(repaintContext).devicePixelRatio;
            captured = await render
                .toImage(pixelRatio: capturedScale)
                .timeout(const Duration(milliseconds: 240));
          } catch (_) {
            captured = null;
            capturedScale = 1.0;
          }
        }
      }

      if (!mounted) {
        captured?.dispose();
        return;
      }

      setState(() {
        _disposePreviousFrameImage();
        _previousFrameImage = captured;
        _previousFrameScale = capturedScale;
        _displayedThemeIndex = nextThemeIndex;
        _displayedRevealKey = nextRevealKey;
        _displayedRevealOrigin = nextRevealOrigin;
      });
    } finally {
      _capturingThemeFrame = false;
      if (_pendingThemeSync && mounted) {
        _pendingThemeSync = false;
        Future.microtask(_onThemeChanged);
      }
    }
  }

  void _disposePreviousFrameImage() {
    _previousFrameImage?.dispose();
    _previousFrameImage = null;
    _previousFrameScale = 1;
  }

  void _onRevealComplete() {
    if (!mounted || _previousFrameImage == null) {
      return;
    }
    setState(_disposePreviousFrameImage);
  }

  void _onOnboardingComplete() {
    _state.completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      state: _state,
      child: ValueListenableBuilder<int>(
        valueListenable: _state.languageChanges,
        builder: (context, _, child) {
          final text = AppText(_state.language);
          return AppTextScope(
            text: text,
            child: ValueListenableBuilder<int>(
              valueListenable: _state.themeChanges,
              builder: (context, _, child) {
                final themeChoice =
                    AppThemes.choices[_displayedThemeIndex.clamp(
                      0,
                      AppThemes.choices.length - 1,
                    )];
                return MaterialApp(
                  debugShowCheckedModeBanner: false,
                  title: text.appName,
                  locale: text.appLanguage.locale,
                  supportedLocales: AppText.supportedLocales,
                  localizationsDelegates: const [
                    GlobalMaterialLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                  ],
                  themeAnimationDuration: Duration.zero,
                  themeAnimationCurve: Curves.linear,
                  scrollBehavior: const _NoGlowScrollBehavior(),
                  theme: themeChoice.data,
                  builder: (context, child) {
                    final themedChild = Directionality(
                      textDirection: text.direction,
                      child: RepaintBoundary(
                        key: _repaintKey,
                        child: Theme(
                          data: themeChoice.data,
                          child: child ?? const SizedBox.shrink(),
                        ),
                      ),
                    );
                    return ThemeCircularRevealHost(
                      revealKey: _displayedRevealKey,
                      revealOrigin: _displayedRevealOrigin,
                      previousFrameImage: _previousFrameImage,
                      previousFrameScale: _previousFrameScale,
                      onRevealComplete: _onRevealComplete,
                      child: themedChild,
                    );
                  },
                  home: AnimatedBuilder(
                    animation: _state,
                    builder: (context, _) => _buildHome(),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildHome() {
    if (!_prefsLoaded) {
      // Show a blank themed screen while prefs are loading
      return const Scaffold(backgroundColor: Colors.transparent);
    }
    if (!_state.hasSeenOnboarding) {
      return OnboardingScreen(onComplete: _onOnboardingComplete);
    }
    return const HomePage();
  }
}

class ThemeCircularRevealHost extends StatefulWidget {
  const ThemeCircularRevealHost({
    super.key,
    required this.revealKey,
    required this.revealOrigin,
    required this.previousFrameImage,
    required this.previousFrameScale,
    required this.onRevealComplete,
    required this.child,
  });

  final int revealKey;
  final Offset? revealOrigin;
  final ui.Image? previousFrameImage;
  final double previousFrameScale;
  final VoidCallback onRevealComplete;
  final Widget child;

  @override
  State<ThemeCircularRevealHost> createState() =>
      _ThemeCircularRevealHostState();
}

class _ThemeCircularRevealHostState extends State<ThemeCircularRevealHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _revealController;
  late final Animation<double> _revealCurve;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: 1,
    );
    _revealCurve = CurvedAnimation(
      parent: _revealController,
      curve: Curves.easeOutCubic,
    );
    _revealController.addStatusListener((status) {
      if (status == AnimationStatus.completed && _isAnimating) {
        _isAnimating = false;
        widget.onRevealComplete();
        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant ThemeCircularRevealHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.revealKey == oldWidget.revealKey) {
      return;
    }
    if (widget.previousFrameImage == null) {
      _isAnimating = false;
      _revealController.value = 1;
      widget.onRevealComplete();
      return;
    }
    _isAnimating = true;
    _revealController.forward(from: 0);
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentChild = KeyedSubtree(
      key: ValueKey(widget.revealKey),
      child: widget.child,
    );
    if (!_isAnimating || widget.previousFrameImage == null) {
      return currentChild;
    }
    return AnimatedBuilder(
      animation: _revealCurve,
      child: currentChild,
      builder: (context, child) {
        final size = MediaQuery.sizeOf(context);
        final center = _resolveRevealCenter(size, widget.revealOrigin);
        final radius = _maxDistanceToCorners(center, size) * _revealCurve.value;
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: RawImage(
                image: widget.previousFrameImage,
                fit: BoxFit.cover,
                scale: widget.previousFrameScale,
                filterQuality: FilterQuality.high,
              ),
            ),
            Positioned.fill(
              child: ShaderMask(
                shaderCallback: (bounds) {
                  return RadialGradient(
                    center: Alignment(
                      (center.dx - bounds.width / 2) / (bounds.width / 2),
                      (center.dy - bounds.height / 2) / (bounds.height / 2),
                    ),
                    radius: radius / math.max(bounds.width, bounds.height) * 2,
                    colors: const [
                      Colors.white,
                      Colors.white,
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.98, 1.0],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstIn,
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }

  Offset _resolveRevealCenter(Size size, Offset? revealOrigin) {
    final fallback = Offset(size.width / 2, size.height / 2);
    if (revealOrigin == null) {
      return fallback;
    }
    final dx = revealOrigin.dx.clamp(0.0, size.width).toDouble();
    final dy = revealOrigin.dy.clamp(0.0, size.height).toDouble();
    return Offset(dx, dy);
  }

  double _maxDistanceToCorners(Offset center, Size size) {
    final corners = <Offset>[
      const Offset(0, 0),
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ];
    return corners.map((corner) => (corner - center).distance).reduce(math.max);
  }
}

class _NoGlowScrollBehavior extends MaterialScrollBehavior {
  const _NoGlowScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
