import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppAnimations {
  static CustomTransitionPage<void> pageTransition({
    required Widget child,
    bool forward = true,
  }) {
    return CustomTransitionPage<void>(
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        final offset = forward
            ? Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero).animate(curved)
            : Tween<Offset>(begin: const Offset(-0.08, 0), end: Offset.zero).animate(curved);
        final fade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
          reverseCurve: const Interval(0.4, 1.0, curve: Curves.easeIn),
        ));
        return SlideTransition(
          position: offset,
          child: FadeTransition(
            opacity: fade,
            child: child,
          ),
        );
      },
    );
  }
}

class StaggeredList extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double delay;

  const StaggeredList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.delay = 0.05,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return _StaggeredItem(
          index: index,
          delay: delay,
          child: itemBuilder(context, index),
        );
      },
    );
  }
}

class StaggeredListView extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double delay;

  const StaggeredListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.delay = 0.04,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return _StaggeredItem(
          index: index,
          delay: delay,
          child: itemBuilder(context, index),
        );
      },
    );
  }
}

class StaggeredColumn extends StatelessWidget {
  final List<Widget> children;
  final double delay;

  const StaggeredColumn({
    super.key,
    required this.children,
    this.delay = 0.05,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(children.length, (i) {
        return _StaggeredItem(
          index: i,
          delay: delay,
          child: children[i],
        );
      }),
    );
  }
}

class _StaggeredItem extends StatefulWidget {
  final int index;
  final double delay;
  final Widget child;

  const _StaggeredItem({
    required this.index,
    required this.delay,
    required this.child,
  });

  @override
  State<_StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<_StaggeredItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (300 + widget.index * widget.delay * 1000).round().clamp(300, 800)),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    Future.delayed(Duration(milliseconds: (widget.index * widget.delay * 1000).round()), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

class TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final Duration duration;

  const TapScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.97,
    this.duration = const Duration(milliseconds: 120),
  });

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale> {
  double _currentScale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _currentScale = widget.scale),
      onTapUp: (_) => _animateBack(),
      onTapCancel: () => _animateBack(),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _currentScale,
        duration: widget.duration,
        curve: Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }

  void _animateBack() {
    setState(() => _currentScale = 1.0);
  }
}

class AnimatedNavIcon extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final bool isActive;
  final double size;

  const AnimatedNavIcon({
    super.key,
    required this.icon,
    required this.activeIcon,
    required this.isActive,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return ScaleTransition(scale: animation, child: child);
      },
      child: Icon(
        isActive ? activeIcon : icon,
        key: ValueKey<bool>(isActive),
        size: size,
      ),
    );
  }
}
