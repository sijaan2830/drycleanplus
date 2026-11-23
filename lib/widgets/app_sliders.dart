import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ChipSlider — horizontal pill slider
//   • items slide in one after another
//   • the selected item glides to the centre
//   • soft edge fade, press-down bounce, haptic tick
// ─────────────────────────────────────────────────────────────────────────────

class ChipSlider extends StatefulWidget {
  final int itemCount;
  final int selectedIndex;
  final Widget Function(BuildContext context, int index, bool selected) itemBuilder;
  final ValueChanged<int> onSelected;
  final double height;
  final double spacing;
  final EdgeInsets padding;

  const ChipSlider({
    super.key,
    required this.itemCount,
    required this.selectedIndex,
    required this.itemBuilder,
    required this.onSelected,
    this.height = 56,
    this.spacing = 10,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  State<ChipSlider> createState() => _ChipSliderState();
}

class _ChipSliderState extends State<ChipSlider> {
  final ScrollController _scroll = ScrollController();
  final GlobalKey _viewportKey = GlobalKey();
  List<GlobalKey> _keys = [];

  @override
  void initState() {
    super.initState();
    _keys = List.generate(widget.itemCount, (_) => GlobalKey());
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerSelected(animate: false));
  }

  @override
  void didUpdateWidget(covariant ChipSlider old) {
    super.didUpdateWidget(old);
    if (old.itemCount != widget.itemCount) {
      _keys = List.generate(widget.itemCount, (_) => GlobalKey());
    }
    if (old.selectedIndex != widget.selectedIndex || old.itemCount != widget.itemCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _centerSelected());
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _centerSelected({bool animate = true}) {
    if (!mounted || !_scroll.hasClients) return;
    final i = widget.selectedIndex;
    if (i < 0 || i >= _keys.length) return;
    final ctx = _keys[i].currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    final viewportBox = _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || viewportBox == null || !viewportBox.hasSize) return;

    final itemOffset = box.localToGlobal(Offset.zero, ancestor: viewportBox);
    final targetOffset = _scroll.offset + itemOffset.dx - (viewportBox.size.width - box.size.width) / 2;
    final clamped = targetOffset.clamp(0.0, _scroll.position.maxScrollExtent);

    if (animate) {
      _scroll.animateTo(
        clamped,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scroll.jumpTo(clamped);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) => const LinearGradient(
          colors: [Color(0x00FFFFFF), Colors.white, Colors.white, Color(0x00FFFFFF)],
          stops: [0.0, 0.05, 0.93, 1.0],
        ).createShader(rect),
        child: SingleChildScrollView(
          key: _viewportKey,
          controller: _scroll,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: widget.padding,
          child: Row(
            children: List.generate(widget.itemCount, (i) {
              final selected = i == widget.selectedIndex;
              return Padding(
                padding: EdgeInsets.only(right: i == widget.itemCount - 1 ? 0 : widget.spacing),
                child: _SlideIn(
                  index: i,
                  child: _Pressable(
                    key: _keys[i],
                    onTap: () {
                      if (i != widget.selectedIndex) HapticFeedback.selectionClick();
                      widget.onSelected(i);
                    },
                    child: widget.itemBuilder(context, i, selected),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// Staggered fade + slide-in the first time an item appears.
class _SlideIn extends StatelessWidget {
  final int index;
  final Widget child;
  const _SlideIn({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + index * 90),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(28 * (1 - v), 0), child: child),
      ),
      child: child,
    );
  }
}

class _Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _Pressable({super.key, required this.child, required this.onTap});

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CardCarousel — snapping PageView
//   • centre card is full size, neighbours shrink and fade
//   • optional auto-play that pauses while the user touches it
//   • animated dots, the active dot fills up like a progress bar
// ─────────────────────────────────────────────────────────────────────────────

class CardCarousel extends StatefulWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double height;
  final double viewportFraction;
  final bool autoPlay;
  final Duration interval;
  final bool showDots;
  final Color dotColor;

  const CardCarousel({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.height = 180,
    this.viewportFraction = 0.86,
    this.autoPlay = false,
    this.interval = const Duration(seconds: 4),
    this.showDots = true,
    this.dotColor = Colors.white,
  });

  @override
  State<CardCarousel> createState() => _CardCarouselState();
}

class _CardCarouselState extends State<CardCarousel> {
  late final PageController _controller;
  Timer? _timer;
  Timer? _resume;
  int _current = 0;
  bool _touching = false;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: widget.viewportFraction);
    _startAutoPlay();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _resume?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _timer?.cancel();
    if (!widget.autoPlay || widget.itemCount < 2) return;
    _timer = Timer.periodic(widget.interval, (_) {
      if (!mounted || _touching || !_controller.hasClients) return;
      final next = (_current + 1) % widget.itemCount;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _pause() {
    _touching = true;
    _resume?.cancel();
  }

  void _resumeLater() {
    _resume?.cancel();
    _resume = Timer(const Duration(seconds: 3), () {
      _touching = false;
      if (mounted) setState(() {}); // restart the progress fill
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.height,
          child: Listener(
            onPointerDown: (PointerDownEvent _) => _pause(),
            onPointerUp: (PointerUpEvent _) => _resumeLater(),
            onPointerCancel: (PointerCancelEvent _) => _resumeLater(),
            child: PageView.builder(
              controller: _controller,
              clipBehavior: Clip.none,
              physics: const BouncingScrollPhysics(),
              itemCount: widget.itemCount,
              onPageChanged: (i) {
                HapticFeedback.selectionClick();
                setState(() => _current = i);
              },
              itemBuilder: (context, i) {
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    double page = _current.toDouble();
                    if (_controller.hasClients && _controller.position.haveDimensions) {
                      page = _controller.page ?? page;
                    }
                    final d = (page - i).abs().clamp(0.0, 1.0);
                    return Opacity(
                      opacity: 1 - 0.4 * d,
                      child: Transform.scale(
                        scale: 1 - 0.09 * d,
                        child: child,
                      ),
                    );
                  },
                  child: widget.itemBuilder(context, i),
                );
              },
            ),
          ),
        ),
        if (widget.showDots && widget.itemCount > 1) ...[
          const SizedBox(height: 12),
          _buildDots(),
        ],
      ],
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.itemCount, (i) {
        final active = i == _current;
        return GestureDetector(
          onTap: () => _controller.animateToPage(
            i,
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            width: active ? 30 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: widget.dotColor.withOpacity(active ? 0.3 : 0.38),
              borderRadius: BorderRadius.circular(8),
            ),
            child: active
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: widget.autoPlay && !_touching
                        ? TweenAnimationBuilder<double>(
                            key: ValueKey('fill_$_current'),
                            tween: Tween(begin: 0, end: 1),
                            duration: widget.interval,
                            builder: (context, v, _) => Align(
                              alignment: Alignment.centerLeft,
                              widthFactor: v,
                              child: Container(width: 30, color: widget.dotColor),
                            ),
                          )
                        : Container(color: widget.dotColor),
                  )
                : null,
          ),
        );
      }),
    );
  }
}
