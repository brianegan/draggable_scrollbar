import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef Widget DraggableScrollThumbBuilder(
  Color backgroundColor,
  Color labelColor,
  Animation<double> thumbAnimation,
  Animation<double> labelAnimation,
  double height, {
  String dynamicLabelText,
});

typedef String DynamicLabelTextBuilder(double offsetY);

class DraggableScrollbar extends StatefulWidget {
  final BoxScrollView child;
  final DraggableScrollThumbBuilder scrollThumbBuilder;
  final double heightScrollThumb;
  final Color backgroundColor;
  final Color labelColor;
  final EdgeInsetsGeometry padding;
  final Duration scrollbarFadeDuration;
  final Duration scrollbarTimeToFade;
  final DynamicLabelTextBuilder dynamicLabelTextBuilder;
  final ScrollController controller;

  DraggableScrollbar({
    Key key,
    @required this.heightScrollThumb,
    @required this.backgroundColor,
    @required this.scrollThumbBuilder,
    @required this.child,
    @required this.controller,
    this.padding,
    this.scrollbarFadeDuration = const Duration(milliseconds: 300),
    this.scrollbarTimeToFade = const Duration(milliseconds: 600),
    this.dynamicLabelTextBuilder,
    this.labelColor,
  })  : assert(controller != null),
        assert(scrollThumbBuilder != null),
        super(key: key);

  DraggableScrollbar.rrect({
    Key key,
    @required this.heightScrollThumb,
    @required this.backgroundColor,
    @required this.child,
    @required this.controller,
    this.padding,
    this.scrollbarFadeDuration = const Duration(milliseconds: 300),
    this.scrollbarTimeToFade = const Duration(milliseconds: 600),
    this.dynamicLabelTextBuilder,
    this.labelColor,
  })  : scrollThumbBuilder = _scrollThumbBuilderRRect,
        super(key: key);

  DraggableScrollbar.withArrows({
    Key key,
    @required this.heightScrollThumb,
    @required this.backgroundColor,
    @required this.child,
    @required this.controller,
    this.padding,
    this.scrollbarFadeDuration = const Duration(milliseconds: 300),
    this.scrollbarTimeToFade = const Duration(milliseconds: 600),
    this.dynamicLabelTextBuilder,
    this.labelColor,
  })  : scrollThumbBuilder = _scrollThumbArrow,
        super(key: key);

  DraggableScrollbar.asGooglePhotos({
    Key key,
    this.heightScrollThumb = 50.0,
    this.backgroundColor = Colors.white,
    @required this.child,
    @required this.controller,
    this.padding,
    this.scrollbarFadeDuration = const Duration(milliseconds: 300),
    this.scrollbarTimeToFade = const Duration(milliseconds: 600),
    this.dynamicLabelTextBuilder,
    this.labelColor,
  })  : scrollThumbBuilder = _scrollThumbGooglePhotos(heightScrollThumb * 0.6),
        super(key: key);

  @override
  _DraggableScrollbarState createState() => _DraggableScrollbarState();

  static DraggableScrollThumbBuilder _scrollThumbGooglePhotos(double width) {
    return (
      Color backgroundColor,
      Color labelColor,
      Animation<double> thumbAnimation,
      Animation<double> labelAnimation,
      double height, {
      String dynamicLabelText,
    }) {
      final scrollThumb = CustomPaint(
        foregroundPainter: ArrowCustomPainter(Colors.grey),
        child: Material(
          elevation: 4.0,
          child: Container(
            constraints: BoxConstraints.tight(Size(width, height)),
          ),
          color: backgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(height),
            bottomLeft: Radius.circular(height),
            topRight: Radius.circular(5.0),
            bottomRight: Radius.circular(5.0),
          ),
        ),
      );

      return SlideFadeTransition(
        animation: thumbAnimation,
        child: dynamicLabelText == null
            ? scrollThumb
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ScrollLabel(
                    text: dynamicLabelText,
                    animation: labelAnimation,
                    labelColor: labelColor,
                    backgroundColor: backgroundColor,
                  ),
                  scrollThumb,
                ],
              ),
      );
    };
  }

  static Widget _scrollThumbArrow(
    Color backgroundColor,
    Color labelColor,
    Animation<double> thumbAnimation,
    Animation<double> labelAnimation,
    double height, {
    String dynamicLabelText,
  }) {
    final scrollThumb = ClipPath(
      child: Container(
        height: height,
        width: 20.0,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.all(
            Radius.circular(10.0),
          ),
        ),
      ),
      clipper: ArrowClipper(),
    );

    return SlideFadeTransition(
      animation: thumbAnimation,
      child: dynamicLabelText == null
          ? scrollThumb
          : Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ScrollLabel(
                  text: dynamicLabelText,
                  animation: labelAnimation,
                  labelColor: labelColor,
                  backgroundColor: backgroundColor,
                ),
                scrollThumb
              ],
            ),
    );
  }

  //height is better 36.0
  static Widget _scrollThumbBuilderRRect(
    Color backgroundColor,
    Color labelColor,
    Animation<double> thumbAnimation,
    Animation<double> labelAnimation,
    double height, {
    String dynamicLabelText,
  }) {
    return SlideFadeTransition(
      animation: thumbAnimation,
      child: Material(
        elevation: 4.0,
        child: Container(
          constraints: BoxConstraints.tight(
            Size(15.0, height),
          ),
        ),
        color: backgroundColor,
        borderRadius: BorderRadius.all(Radius.circular(7.0)),
      ),
    );
  }
}

class ScrollLabel extends StatelessWidget {
  final Animation<double> animation;
  final Color backgroundColor;
  final Color labelColor;
  final String text;

  const ScrollLabel({
    Key key,
    @required this.text,
    @required this.animation,
    @required this.backgroundColor,
    @required this.labelColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: Container(
        margin: EdgeInsets.only(right: 10.0),
        child: Material(
          elevation: 4.0,
          color: backgroundColor,
          borderRadius: BorderRadius.all(Radius.circular(15.0)),
          child: Container(
            constraints: BoxConstraints.tight(Size(70.0, 30.0)),
            alignment: Alignment.center,
            child: Text(text, style: TextStyle(color: labelColor)),
          ),
        ),
      ),
    );
  }
}

class _DraggableScrollbarState extends State<DraggableScrollbar>
    with TickerProviderStateMixin {
  double _barOffset;
  double _viewOffset;
  bool _isDragInProcess;

  AnimationController _thumbAnimationController;
  Animation<double> _thumbAnimation;
  AnimationController _labelAnimationController;
  Animation<double> _labelAnimation;
  Timer _fadeoutTimer;

  @override
  void initState() {
    super.initState();
    _barOffset = 0.0;
    _viewOffset = 0.0;
    _isDragInProcess = false;

    _thumbAnimationController = AnimationController(
      vsync: this,
      duration: widget.scrollbarFadeDuration,
    );

    _thumbAnimation = CurvedAnimation(
      parent: _thumbAnimationController,
      curve: Curves.fastOutSlowIn,
    );

    _labelAnimationController = AnimationController(
      vsync: this,
      duration: widget.scrollbarFadeDuration,
    );

    _labelAnimation = CurvedAnimation(
      parent: _labelAnimationController,
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  void dispose() {
    _thumbAnimationController.dispose();
    _fadeoutTimer?.cancel();
    super.dispose();
  }

  double get barMaxScrollExtent =>
      context.size.height - widget.heightScrollThumb;

  double get barMinScrollExtent => 0.0;

  double get viewMaxScrollExtent => widget.controller.position.maxScrollExtent;

  double get viewMinScrollExtent => widget.controller.position.minScrollExtent;

  @override
  Widget build(BuildContext context) {
    String label;
    if (widget.dynamicLabelTextBuilder != null) {
      label = widget.dynamicLabelTextBuilder(
        _viewOffset + _barOffset + widget.heightScrollThumb / 2,
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        changePosition(notification);
      },
      child: Stack(
        children: <Widget>[
          widget.child,
          GestureDetector(
            onVerticalDragStart: _onVerticalDragStart,
            onVerticalDragUpdate: _onVerticalDragUpdate,
            onVerticalDragEnd: _onVerticalDragEnd,
            child: Container(
              alignment: Alignment.topRight,
              margin: EdgeInsets.only(top: _barOffset),
              padding: widget.padding,
              child: widget.scrollThumbBuilder(
                widget.backgroundColor,
                widget.labelColor,
                _thumbAnimation,
                _labelAnimation,
                widget.heightScrollThumb,
                dynamicLabelText: label,
              ),
            ),
          )
        ],
      ),
    );
  }

  //scroll bar has received notification that it's view was scrolled
  //so it should also changes his position
  //but only if it isn't dragged
  changePosition(ScrollNotification notification) {
    if (_isDragInProcess) {
      return;
    }

    setState(() {
      if (notification is ScrollUpdateNotification) {
        _barOffset += getBarDelta(
          notification.scrollDelta,
          barMaxScrollExtent,
          viewMaxScrollExtent,
        );

        if (_barOffset < barMinScrollExtent) {
          _barOffset = barMinScrollExtent;
        }
        if (_barOffset > barMaxScrollExtent) {
          _barOffset = barMaxScrollExtent;
        }

        _viewOffset += notification.scrollDelta;
        if (_viewOffset < widget.controller.position.minScrollExtent) {
          _viewOffset = widget.controller.position.minScrollExtent;
        }
        if (_viewOffset > viewMaxScrollExtent) {
          _viewOffset = viewMaxScrollExtent;
        }
      }

      if (notification is ScrollUpdateNotification ||
          notification is OverscrollNotification) {
        if (_thumbAnimationController.status != AnimationStatus.forward) {
          _thumbAnimationController.forward();
        }

        _fadeoutTimer?.cancel();
        _fadeoutTimer = Timer(widget.scrollbarTimeToFade, () {
          _thumbAnimationController.reverse();
          _labelAnimationController.reverse();
          _fadeoutTimer = null;
        });
      }
    });
  }

  double getBarDelta(
    double scrollViewDelta,
    double barMaxScrollExtent,
    double viewMaxScrollExtent,
  ) {
    return scrollViewDelta * barMaxScrollExtent / viewMaxScrollExtent;
  }

  double getScrollViewDelta(
    double barDelta,
    double barMaxScrollExtent,
    double viewMaxScrollExtent,
  ) {
    return barDelta * viewMaxScrollExtent / barMaxScrollExtent;
  }

  void _onVerticalDragStart(DragStartDetails details) {
    setState(() {
      _isDragInProcess = true;
      _labelAnimationController.forward();
      _fadeoutTimer?.cancel();
    });
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_thumbAnimationController.status != AnimationStatus.forward) {
      _thumbAnimationController.forward();
    }
    setState(() {
      if (_isDragInProcess) {
        _barOffset += details.delta.dy;

        if (_barOffset < barMinScrollExtent) {
          _barOffset = barMinScrollExtent;
        }
        if (_barOffset > barMaxScrollExtent) {
          _barOffset = barMaxScrollExtent;
        }

        double viewDelta = getScrollViewDelta(
            details.delta.dy, barMaxScrollExtent, viewMaxScrollExtent);

        _viewOffset = widget.controller.position.pixels + viewDelta;
        if (_viewOffset < widget.controller.position.minScrollExtent) {
          _viewOffset = widget.controller.position.minScrollExtent;
        }
        if (_viewOffset > viewMaxScrollExtent) {
          _viewOffset = viewMaxScrollExtent;
        }
        widget.controller.jumpTo(_viewOffset);
      }
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    _fadeoutTimer = Timer(widget.scrollbarTimeToFade, () {
      _thumbAnimationController.reverse();
      _labelAnimationController.reverse();
      _fadeoutTimer = null;
    });
    setState(() {
      _isDragInProcess = false;
    });
  }
}

class ArrowCustomPainter extends CustomPainter {
  Color color;

  ArrowCustomPainter(this.color);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const width = 12.0;
    const height = 8.0;
    final baseX = size.width / 2;
    final baseY = size.height / 2;

    canvas.drawPath(
      _trianglePath(Offset(baseX, baseY - 2.0), width, height, true),
      paint,
    );
    canvas.drawPath(
      _trianglePath(Offset(baseX, baseY + 2.0), width, height, false),
      paint,
    );
  }

  static Path _trianglePath(Offset o, double width, double height, bool isUp) {
    return Path()
      ..moveTo(o.dx, o.dy)
      ..lineTo(o.dx + width, o.dy)
      ..lineTo(o.dx + (width / 2), isUp ? o.dy - height : o.dy + height)
      ..close();
  }
}

class ArrowClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0.0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0.0);
    path.lineTo(0.0, 0.0);
    path.close();

    double arrowWidth = 8.0;
    double startPointX = (size.width - arrowWidth) / 2;
    double startPointY = size.height / 2 - arrowWidth / 2;
    path.moveTo(startPointX, startPointY);
    path.lineTo(startPointX + arrowWidth / 2, startPointY - arrowWidth / 2);
    path.lineTo(startPointX + arrowWidth, startPointY);
    path.lineTo(startPointX + arrowWidth, startPointY + 1.0);
    path.lineTo(
        startPointX + arrowWidth / 2, startPointY - arrowWidth / 2 + 1.0);
    path.lineTo(startPointX, startPointY + 1.0);
    path.close();

    startPointY = size.height / 2 + arrowWidth / 2;
    path.moveTo(startPointX + arrowWidth, startPointY);
    path.lineTo(startPointX + arrowWidth / 2, startPointY + arrowWidth / 2);
    path.lineTo(startPointX, startPointY);
    path.lineTo(startPointX, startPointY - 1.0);
    path.lineTo(
        startPointX + arrowWidth / 2, startPointY + arrowWidth / 2 - 1.0);
    path.lineTo(startPointX + arrowWidth, startPointY - 1.0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class SlideFadeTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const SlideFadeTransition({
    Key key,
    @required this.animation,
    @required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) => animation.value == 0.0 ? Container() : child,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0.3, 0.0),
          end: const Offset(0.0, 0.0),
        ).animate(animation),
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
    );
  }
}
