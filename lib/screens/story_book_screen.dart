// ============================================================================
// Story Book Screen — Page-by-page reading experience
//
// CHANGES:
//  • _AdaptiveText: binary-search font size so text always fills the box
//    without overflowing and never looks uncomfortably small.
//  • AnimatedSwitcher for smooth page transitions.
//  • Landscape shows TWO full pages side-by-side (like a real book).
//  • Swipe + keyboard + arrow-button navigation all work in both orientations.
//  • Cleaner visual hierarchy, consistent rounded corners.
// ============================================================================

import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animated_background/animated_background.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/book.dart';
import '../providers/settings_provider.dart';

class StoryBookScreen extends StatefulWidget {
  static const routeName = '/story_book';
  final Book book;

  const StoryBookScreen({super.key, required this.book});

  @override
  State<StoryBookScreen> createState() => _StoryBookScreenState();
}

class _StoryBookScreenState extends State<StoryBookScreen>
    with TickerProviderStateMixin {
  int _currentPage = 0;
  final FocusNode _focusNode = FocusNode();

  List<BookPage> get _pages => widget.book.pages;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_currentPage < _pages.length - 1) {
      setState(() => _currentPage++);
    }
  }

  void _goPrev() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
        event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _goNext();
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
        event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _goPrev();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;

    final current = _pages[_currentPage];
    final next = (isLandscape && _currentPage + 1 < _pages.length)
        ? _pages[_currentPage + 1]
        : null;

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: () => _focusNode.requestFocus(),
        onHorizontalDragEnd: settings.isSwipeEnabled
            ? (details) {
          if ((details.primaryVelocity ?? 0) < -200) _goNext();
          if ((details.primaryVelocity ?? 0) > 200) _goPrev();
          _focusNode.requestFocus();
        }
            : null,
        child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: Text(
              widget.book.title,
              style: GoogleFonts.fredoka(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          body: Stack(
            children: [
              // ── Animated background ──────────────────────────────────────
              Positioned.fill(
                child: RepaintBoundary(
                  child: AnimatedBackground(
                    vsync: this,
                    behaviour: RandomParticleBehaviour(
                      options: ParticleOptions(
                        baseColor: settings.particleColor,
                        particleCount: 35,
                        spawnMinSpeed: 8,
                        spawnMaxSpeed: 35,
                        spawnMinRadius: 1,
                        spawnMaxRadius: 3,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            settings.primaryGradientStart,
                            settings.primaryGradientEnd,
                            const Color(0xFF764ba2),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Page content ─────────────────────────────────────────────
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isLandscape ? 16 : 12,
                    8,
                    isLandscape ? 16 : 12,
                    72, // space for bottom indicators
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.04, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: isLandscape
                        ? _LandscapeSpread(
                      key: ValueKey('spread-$_currentPage'),
                      left: current,
                      right: next,
                      settings: settings,
                    )
                        : _SinglePage(
                      key: ValueKey('page-$_currentPage'),
                      page: current,
                      settings: settings,
                    ),
                  ),
                ),
              ),

              // ── Bottom controls ──────────────────────────────────────────
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _BottomBar(
                  currentPage: _currentPage,
                  totalPages: _pages.length,
                  onPrev: _currentPage > 0 ? _goPrev : null,
                  onNext: _currentPage < _pages.length - 1 ? _goNext : null,
                  settings: settings,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Single Page (portrait) ──────────────────────────────────────────────────

class _SinglePage extends StatelessWidget {
  final BookPage page;
  final SettingsProvider settings;

  const _SinglePage({super.key, required this.page, required this.settings});

  @override
  Widget build(BuildContext context) {
    return _BookPageCard(page: page, settings: settings);
  }
}

// ─── Landscape Spread (two pages side by side) ───────────────────────────────

class _LandscapeSpread extends StatelessWidget {
  final BookPage left;
  final BookPage? right;
  final SettingsProvider settings;

  const _LandscapeSpread({
    super.key,
    required this.left,
    required this.right,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _BookPageCard(page: left, settings: settings)),
        if (right != null) ...[
          const SizedBox(width: 16),
          Expanded(child: _BookPageCard(page: right!, settings: settings)),
        ],
      ],
    );
  }
}

// ─── Book Page Card ───────────────────────────────────────────────────────────

class _BookPageCard extends StatelessWidget {
  final BookPage page;
  final SettingsProvider settings;

  const _BookPageCard({required this.page, required this.settings});

  String get _cleanBase64 {
    final raw = page.imagePath;
    if (raw.isEmpty) return '';
    return raw.contains(',') ? raw.split(',').last : raw;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // Image — 55% of card height
            Expanded(
              flex: 55,
              child: _ImagePanel(
                base64Data: _cleanBase64,
                isGenerated: page.isImageGenerated,
              ),
            ),

            // Divider
            Container(height: 1, color: Colors.grey.shade100),

            // Text — 45% of card height
            Expanded(
              flex: 45,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                child: _AdaptiveText(text: page.textContent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Adaptive Text — binary-searches the best font size ──────────────────────
// Starts at maxFontSize and steps down until the text fits the available
// height. Falls back to scrollable if even minFontSize doesn't fit.

class _AdaptiveText extends StatelessWidget {
  final String text;
  final double maxFontSize;
  final double minFontSize;

  const _AdaptiveText({
    required this.text,
    this.maxFontSize = 21,
    this.minFontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bestSize = _findBestSize(
          constraints.maxWidth - 4,
          constraints.maxHeight,
        );
        final needsScroll = bestSize <= minFontSize &&
            !_textFits(minFontSize, constraints.maxWidth - 4,
                constraints.maxHeight);

        final textWidget = Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: bestSize,
            color: Colors.black87,
            height: 1.55,
          ),
        );

        if (needsScroll) {
          return SingleChildScrollView(child: textWidget);
        }
        return Center(child: textWidget);
      },
    );
  }

  double _findBestSize(double maxWidth, double maxHeight) {
    double lo = minFontSize;
    double hi = maxFontSize;

    // Binary search for largest size that fits
    while (hi - lo > 0.5) {
      final mid = (lo + hi) / 2;
      if (_textFits(mid, maxWidth, maxHeight)) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  bool _textFits(double fontSize, double maxWidth, double maxHeight) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.poppins(fontSize: fontSize, height: 1.55),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    return tp.height <= maxHeight;
  }
}

// ─── Image Panel ─────────────────────────────────────────────────────────────

class _ImagePanel extends StatelessWidget {
  final String base64Data;
  final bool isGenerated;

  const _ImagePanel({required this.base64Data, required this.isGenerated});

  @override
  Widget build(BuildContext context) {
    if (base64Data.isEmpty) {
      return Container(
        color: const Color(0xFFF0EDFF),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: Color(0xFF667eea),
                strokeWidth: 2.5,
              ),
              const SizedBox(height: 12),
              Text(
                'Painting your illustration…',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF667eea),
                ),
              ),
            ],
          ),
        ),
      );
    }

    try {
      final bytes = base64Decode(base64Data);
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        width: double.infinity,
        errorBuilder: (_, __, ___) => const _BrokenImagePlaceholder(),
      );
    } catch (_) {
      return const _BrokenImagePlaceholder();
    }
  }
}

class _BrokenImagePlaceholder extends StatelessWidget {
  const _BrokenImagePlaceholder();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: const Center(
        child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey),
      ),
    );
  }
}

// ─── Bottom Bar — indicators + nav arrows ────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final SettingsProvider settings;

  const _BottomBar({
    required this.currentPage,
    required this.totalPages,
    required this.onPrev,
    required this.onNext,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Prev button
          _NavButton(
            icon: Icons.arrow_back_ios_new,
            onPressed: onPrev,
          ),

          // Indicators
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(totalPages, (i) {
                  final active = i == currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: active
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                      boxShadow: active
                          ? [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ]
                          : null,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 4),
              Text(
                '${currentPage + 1} / $totalPages',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          // Next button
          _NavButton(
            icon: Icons.arrow_forward_ios,
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _NavButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: onPressed != null ? 1.0 : 0.3,
      duration: const Duration(milliseconds: 200),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: onPressed != null
              ? const LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          )
              : null,
          color: onPressed == null ? Colors.white24 : null,
          shape: BoxShape.circle,
          boxShadow: onPressed != null
              ? [
            BoxShadow(
              color: const Color(0xFF667eea).withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ]
              : null,
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(icon, size: 20, color: Colors.white),
          onPressed: onPressed,
        ),
      ),
    );
  }
}