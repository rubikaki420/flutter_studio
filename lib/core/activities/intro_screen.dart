import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:flutter_studio/core/activities/home_activity.dart';
import 'package:flutter_studio/core/service/app_start_service.dart';

/*
  This code copied form Cloude Ai
*/
const _cSideBar = Color(0xFF1E1E1E);
const _cBackground = Color(0xFF252526);
const _cHover = Color(0xFF3C3C3C);
const _cText = Color(0xFFCDD6F4);
const _cSubtext1 = Color(0xFFA6ADC8);
const _cOverlay0 = Color(0xFF6C7086);
const _cGreen = Color(0xFFA6E3A1);
const _cBlue = Color(0xFF89B4FA);
const _cMauve = Color(0xFFCBA6F7);
const _cPeach = Color(0xFFFAB387);

class IntroGate extends StatefulWidget {
  const IntroGate({super.key});
  @override
  State<IntroGate> createState() => _IntroGateState();
}

class _IntroGateState extends State<IntroGate> {
  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    // Build a list of which slides are already done.
    final List<bool> done = await _checkAllSlides();

    if (!mounted) return;

    // If every slide is satisfied, go straight to Home.
    if (done.every((d) => d)) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeActivity()),
      );
      return;
    }

    // Otherwise launch the intro starting from the first unsatisfied slide.
    final int startIndex = done.indexWhere((d) => !d);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => IntroScreen(initialDone: done, initialPage: startIndex),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: _cSideBar,
      body: Center(child: CircularProgressIndicator(color: _cBlue)),
    );
  }
}

Future<List<bool>> _checkAllSlides() async {
  final results = <bool>[];
  for (final slide in _slides) {
    results.add(await _isSlideComplete(slide));
  }
  return results;
}

Future<bool> _isSlideComplete(_Slide slide) async {
  switch (slide.kind) {
    case _SlideKind.permission:
      // .status never triggers a dialog — safe to call anytime.
      final status = await slide.permission!.status;
      return status.isGranted;
    case _SlideKind.termux:
      // isTermuxReady() is async in AppStartService (reads SharedPreferences).
      return await AppStartService.isTermuxReady();
  }
}

enum _SlideKind { permission, termux }

class _Slide {
  final String icon;
  final String title;
  final String subtitle;
  final String description;
  final Color accent;
  final _SlideKind kind;
  final Permission? permission;
  final String pendingLabel;
  final String doneLabel;

  const _Slide({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.accent,
    required this.kind,
    this.permission,
    required this.pendingLabel,
    required this.doneLabel,
  });
}

const _slides = <_Slide>[
  _Slide(
    icon: '💾',
    title: 'Own Your\nFiles',
    subtitle: 'Storage Permission',
    description:
        'Full access to external storage lets Flutter Studio read, write, and '
        'manage your project files, assets, and build outputs freely.',
    accent: _cBlue,
    kind: _SlideKind.permission,
    permission: Permission.manageExternalStorage,
    pendingLabel: 'Allow Storage Access',
    doneLabel: 'Storage access granted',
  ),
  _Slide(
    icon: '🔔',
    title: 'Stay in the\nLoop',
    subtitle: 'Notification Access',
    description:
        'Get notified when your builds finish, errors occur, or long-running '
        'Termux tasks complete — even when the app is in the background.',
    accent: _cGreen,
    kind: _SlideKind.permission,
    permission: Permission.notification,
    pendingLabel: 'Allow Notifications',
    doneLabel: 'Notifications enabled',
  ),
  _Slide(
    icon: '📇',
    title: 'Build &\nConnect',
    subtitle: 'Contacts Permission',
    description:
        'Contact read permission lets you share projects and collaborate with '
        'teammates directly from your address book inside the IDE.',
    accent: _cMauve,
    kind: _SlideKind.permission,
    permission: Permission.contacts,
    pendingLabel: 'Allow Contacts Access',
    doneLabel: 'Contacts access granted',
  ),
  _Slide(
    icon: '⚡',
    title: 'Power Up\nTermux',
    subtitle: 'First-Launch Setup',
    description:
        'Flutter Studio uses Termux to compile and run your code. Tap below '
        'to install packages and configure the environment — this only happens once.',
    accent: _cPeach,
    kind: _SlideKind.termux,
    pendingLabel: 'Initialize Termux',
    doneLabel: 'Termux is ready',
  ),
];

class IntroScreen extends StatefulWidget {
  final List<bool> initialDone;
  final int initialPage;

  const IntroScreen({
    super.key,
    required this.initialDone,
    required this.initialPage,
  });

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late int _current;
  late final List<bool> _done;

  bool _termuxRunning = false;
  String _termuxStatus = '';

  late final AnimationController _cardAnim;
  late final Animation<double> _cardScale;
  late final Animation<double> _cardFade;

  @override
  void initState() {
    super.initState();

    _current = widget.initialPage;
    _done = List.of(widget.initialDone);

    _pageController = PageController(initialPage: _current);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: _cBackground,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    _cardAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _cardScale = Tween<double>(
      begin: 0.94,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _cardAnim, curve: Curves.easeOutBack));
    _cardFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _cardAnim, curve: Curves.easeOut));

    _cardAnim.forward();
  }

  @override
  void dispose() {
    _cardAnim.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _requestPermission() async {
    final slide = _slides[_current];
    PermissionStatus status;

    if (slide.permission == Permission.manageExternalStorage) {
      // Try MANAGE_EXTERNAL_STORAGE first, fall back to READ/WRITE storage.
      status = await Permission.manageExternalStorage.request();
      if (!status.isGranted) status = await Permission.storage.request();
    } else if (slide.permission == Permission.notification) {
      // Android 13+ (API 33): POST_NOTIFICATIONS must be requested explicitly.
      // On older versions .request() is a no-op and returns isGranted = true.
      status = await Permission.notification.request();
      // If permanently denied, open Settings so the user can flip it manually.
      if (status.isPermanentlyDenied && mounted) {
        await openAppSettings();
        status = await Permission.notification.status;
      }
    } else {
      status = await slide.permission!.request();
      if (status.isPermanentlyDenied && mounted) {
        await openAppSettings();
        status = await slide.permission!.status;
      }
    }

    if (mounted) setState(() => _done[_current] = status.isGranted);
  }

  Future<void> _runTermux() async {
    if (_termuxRunning || _done[_current]) return;
    setState(() {
      _termuxRunning = true;
      _termuxStatus = 'Initializing…';
    });
    try {
      await AppStartService.handleFirstLaunchFlow();
      // Verify using the same source of truth as IntroGate so this slide
      // is never shown again once Termux has been initialized.
      final ready = await AppStartService.isTermuxReady();
      if (mounted) {
        setState(() {
          _done[_current] = ready;
          _termuxRunning = false;
          _termuxStatus = ready ? 'Done!' : 'Failed — tap to retry';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _termuxRunning = false;
          _termuxStatus = 'Failed — tap to retry';
        });
      }
    }
  }

  void _next() {
    if (_current < _slides.length - 1) {
      _cardAnim.reset();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  void _finish() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, _, _) => const HomeActivity(),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cSideBar,
      appBar: AppBar(
        backgroundColor: _cBackground,
        elevation: 0,
        toolbarHeight: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: _cBackground,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _slides.length,
            onPageChanged: (i) {
              setState(() => _current = i);
              _cardAnim.forward(from: 0);
            },
            itemBuilder: (_, i) => _SlidePage(
              slide: _slides[i],
              done: _done[i],
              cardScale: _cardScale,
              cardFade: _cardFade,
              termuxRunning: _termuxRunning,
              termuxStatus: _termuxStatus,
              onPermRequest: _requestPermission,
              onTermuxRun: _runTermux,
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomBar(
              current: _current,
              total: _slides.length,
              done: _done,
              onNext: _next,
              onSkip: _finish,
            ),
          ),
        ],
      ),
    );
  }
}

class _SlidePage extends StatelessWidget {
  final _Slide slide;
  final bool done;
  final Animation<double> cardScale;
  final Animation<double> cardFade;
  final bool termuxRunning;
  final String termuxStatus;
  final VoidCallback onPermRequest;
  final VoidCallback onTermuxRun;

  const _SlidePage({
    required this.slide,
    required this.done,
    required this.cardScale,
    required this.cardFade,
    required this.termuxRunning,
    required this.termuxStatus,
    required this.onPermRequest,
    required this.onTermuxRun,
  });

  @override
  Widget build(BuildContext context) {
    final isTermux = slide.kind == _SlideKind.termux;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 52),

            // Icon badge
            ScaleTransition(
              scale: cardScale,
              child: FadeTransition(
                opacity: cardFade,
                child: _IconBadge(slide: slide),
              ),
            ),
            const SizedBox(height: 32),

            // Title
            FadeTransition(
              opacity: cardFade,
              child: Text(
                slide.title,
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  height: 1.06,
                  letterSpacing: -1.2,
                  color: _cText,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Subtitle chip
            FadeTransition(
              opacity: cardFade,
              child: _Chip(label: slide.subtitle, accent: slide.accent),
            ),
            const SizedBox(height: 26),

            // Description card
            ScaleTransition(
              scale: cardScale,
              child: FadeTransition(
                opacity: cardFade,
                child: _DescCard(slide: slide),
              ),
            ),
            const SizedBox(height: 32),

            // Action button
            FadeTransition(
              opacity: cardFade,
              child: _ActionBtn(
                accent: slide.accent,
                done: done,
                loading: isTermux && termuxRunning,
                pendingLabel: slide.pendingLabel,
                doneLabel: slide.doneLabel,
                statusText: isTermux ? termuxStatus : null,
                onTap: isTermux ? onTermuxRun : onPermRequest,
              ),
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final _Slide slide;
  const _IconBadge({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: _cBackground,
        border: Border.all(
          color: slide.accent.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: slide.accent.withValues(alpha: 0.18),
            blurRadius: 28,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: Text(slide.icon, style: const TextStyle(fontSize: 40)),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color accent;
  const _Chip({required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.9,
          color: accent,
        ),
      ),
    );
  }
}

class _DescCard extends StatelessWidget {
  final _Slide slide;
  const _DescCard({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: slide.accent.withValues(alpha: 0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Accent left bar
          Container(
            width: 3,
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [slide.accent, slide.accent.withValues(alpha: 0.10)],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              slide.description,
              style: const TextStyle(
                fontSize: 14,
                color: _cSubtext1,
                height: 1.65,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final Color accent;
  final bool done;
  final bool loading;
  final String pendingLabel;
  final String doneLabel;
  final String? statusText;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.accent,
    required this.done,
    required this.loading,
    required this.pendingLabel,
    required this.doneLabel,
    required this.onTap,
    this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: done
                ? LinearGradient(
                    colors: [
                      accent.withValues(alpha: 0.14),
                      accent.withValues(alpha: 0.07),
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accent, accent.withValues(alpha: 0.65)],
                  ),
            border: done
                ? Border.all(color: accent.withValues(alpha: 0.35))
                : null,
            boxShadow: done
                ? []
                : [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: (done || loading) ? null : onTap,
              child: Center(
                child: loading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: accent,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 260),
                            child: done
                                ? Icon(
                                    Icons.check_circle_rounded,
                                    key: const ValueKey('chk'),
                                    color: accent,
                                    size: 19,
                                  )
                                : Icon(
                                    Icons.lock_open_rounded,
                                    key: const ValueKey('lck'),
                                    color: _cSideBar,
                                    size: 19,
                                  ),
                          ),
                          const SizedBox(width: 9),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 260),
                            child: Text(
                              done ? doneLabel : pendingLabel,
                              key: ValueKey(done),
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                                color: done ? accent : _cSideBar,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
        if (statusText != null && statusText!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            statusText!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: accent.withValues(alpha: 0.7),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int current;
  final int total;
  final List<bool> done;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _BottomBar({
    required this.current,
    required this.total,
    required this.done,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = current == total - 1;
    final accent = _slides[current].accent;

    return Container(
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 38),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_cSideBar.withValues(alpha: 0.0), _cSideBar],
        ),
      ),
      child: Row(
        children: [
          // Progress dots
          Row(
            children: List.generate(total, (i) {
              final isActive = i == current;
              final isDone = done[i];
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 6),
                width: isActive ? 26.0 : 10.0,
                height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: isDone
                      ? _slides[i].accent
                      : isActive
                      ? accent
                      : _cHover,
                  boxShadow: (isActive || isDone)
                      ? [
                          BoxShadow(
                            color: _slides[i].accent.withValues(alpha: 0.4),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              );
            }),
          ),

          const Spacer(),

          if (!isLast)
            TextButton(
              onPressed: onSkip,
              child: const Text(
                'Skip',
                style: TextStyle(
                  color: _cOverlay0,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          const SizedBox(width: 10),

          // Next / Get Started button
          GestureDetector(
            onTap: onNext,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              width: isLast ? 158.0 : 54.0,
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [accent, accent.withValues(alpha: 0.65)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.32),
                    blurRadius: 18,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: isLast
                      ? const Text(
                          'Get Started',
                          key: ValueKey('start'),
                          style: TextStyle(
                            color: _cSideBar,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        )
                      : const Icon(
                          Icons.arrow_forward_rounded,
                          key: ValueKey('arrow'),
                          color: _cSideBar,
                          size: 22,
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
