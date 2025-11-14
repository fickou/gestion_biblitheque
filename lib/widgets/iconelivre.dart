import 'package:flutter/material.dart';

class FloatingBookIcon extends StatefulWidget {
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double size;
  final int delay;

  const FloatingBookIcon({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.size,
    required this.delay,
    super.key,
  });

  @override
  State<FloatingBookIcon> createState() => _FloatingBookIconState();
}

class _FloatingBookIconState extends State<FloatingBookIcon>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 20).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.top,
      bottom: widget.bottom,
      left: widget.left,
      right: widget.right,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (_, child) {
          return Transform.translate(
            offset: Offset(0, _animation.value),
            child: Icon(
              Icons.menu_book,
              size: widget.size,
              color: Colors.white,
            ),
          );
        },
      ),
    );
  }
}
