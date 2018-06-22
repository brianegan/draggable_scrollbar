import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef Widget DraggableScrollThumbBuilder(
  Color color,
  double fadingOpacity,
  double height, {
  String dynamicLabelText,
});

typedef String DynamicLabelTextBuilder(double offsetY);

class DraggableScrollbar extends StatefulWidget {
  final BoxScrollView child;
  final DraggableScrollThumbBuilder scrollThumbBuilder;
  final double heightScrollThumb;
  final Color color;
  final EdgeInsetsGeometry padding;
  final Duration scrollbarFadeDuration;
  final Duration scrollbarTimeToFade;
  final DynamicLabelTextBuilder dynamicLabelTextBuilder;

  DraggableScrollbar({
    Key key,
    @required this.heightScrollThumb,
    @required this.color,
    @required this.scrollThumbBuilder,
    @required this.child,
    this.padding,
    this.scrollbarFadeDuration = const Duration(milliseconds: 300),
    this.scrollbarTimeToFade = const Duration(milliseconds: 600),
    this.dynamicLabelTextBuilder,
  })  : assert(scrollThumbBuilder != null),
        super(key: key);

  DraggableScrollbar.rrect({
    Key key,
    @required this.heightScrollThumb,
    @required this.color,
    @required this.child,
    this.padding,
    this.scrollbarFadeDuration = const Duration(milliseconds: 300),
    this.scrollbarTimeToFade = const Duration(milliseconds: 600),
    this.dynamicLabelTextBuilder,
  })  : scrollThumbBuilder = _scrollThumbBuilderRRect,
        super(key: key);

  DraggableScrollbar.withArrows({
    Key key,
    @required this.heightScrollThumb,
    @required this.color,
    @required this.child,
    this.padding,
    this.scrollbarFadeDuration = const Duration(milliseconds: 300),
    this.scrollbarTimeToFade = const Duration(milliseconds: 600),
    this.dynamicLabelTextBuilder,
  })  : scrollThumbBuilder = _scrollThumbArrow,
        super(key: key);

  DraggableScrollbar.asGooglePhotos({
    Key key,
    this.heightScrollThumb = 50.0,
    this.color = Colors.white,
    @required this.child,
    this.padding,
    this.scrollbarFadeDuration = const Duration(milliseconds: 300),
    this.scrollbarTimeToFade = const Duration(milliseconds: 600),
    this.dynamicLabelTextBuilder,
  })  : scrollThumbBuilder = _scrollThumbGooglePhotos(heightScrollThumb * 0.6),
        super(key: key);

  @override
  _DraggableScrollbarState createState() => _DraggableScrollbarState();

  static DraggableScrollThumbBuilder _scrollThumbGooglePhotos(double width) {
    return (
      Color color,
      double fadingOpacity,
      double height, {
      String dynamicLabelText,
    }) {
      final backgroundColor = calculateOpacity(color, fadingOpacity);

      final scrollThumb = CustomPaint(
        foregroundPainter: ArrowCustomPainter(
          calculateOpacity(Colors.grey, fadingOpacity),
        ),
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

      if (dynamicLabelText == null) {
        return scrollThumb;
      }

      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            margin: EdgeInsets.only(right: 10.0),
            child: Material(
              color: backgroundColor,
              borderRadius: BorderRadius.all(Radius.circular(10.0)),
              child: Container(
                constraints: BoxConstraints.tight(Size(50.0, 20.0)),
                alignment: Alignment.center,
                child: Text(dynamicLabelText),
              ),
            ),
          ),
          scrollThumb,
        ],
      );
    };
  }

  static Widget _scrollThumbArrow(
    Color color,
    double fadingOpacity,
    double height, {
    String dynamicLabelText,
  }) {
    final scrollThumb = ClipPath(
      child: Container(
        height: height,
        width: 20.0,
        decoration: BoxDecoration(
          color: calculateOpacity(color, fadingOpacity),
          borderRadius: BorderRadius.all(
            Radius.circular(10.0),
          ),
        ),
      ),
      clipper: ArrowClipper(),
    );

    if (dynamicLabelText == null) {
      return scrollThumb;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          margin: EdgeInsets.only(right: 30.0),
          child: Material(
            elevation: 8.0,
            color: calculateOpacity(color, fadingOpacity),
            borderRadius: BorderRadius.all(Radius.circular(15.0)),
            child: Container(
              constraints: BoxConstraints.tight(Size(70.0, 30.0)),
              alignment: Alignment.center,
              child: Text(
                dynamicLabelText,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
        scrollThumb
      ],
    );
  }

  //height is better 36.0
  static Widget _scrollThumbBuilderRRect(
    Color color,
    double fadingOpacity,
    double height, {
    String dynamicLabelText,
  }) {
    return Material(
      elevation: 8.0,
      child: Container(
        constraints: BoxConstraints.tight(
          Size(15.0, height),
        ),
      ),
      color: calculateOpacity(color, fadingOpacity),
      borderRadius: BorderRadius.all(Radius.circular(7.0)),
    );
  }

  static Color calculateOpacity(Color color, double fadingOpacity) {
    return color.withOpacity(color.opacity * fadingOpacity);
  }
}

class _DraggableScrollbarState extends State<DraggableScrollbar>
    with TickerProviderStateMixin {
  ScrollController _controller;
  double _barOffset;
  double _viewOffset;
  bool _isDragInProcess;
  DraggableScrollThumb _draggableScrollThumb;
  Color _color;

  AnimationController _fadeoutAnimationController;
  Animation<double> _fadeoutOpacityAnimation;
  Timer _fadeoutTimer;

  @override
  void initState() {
    super.initState();
    _controller = widget.child.controller;
    _barOffset = 0.0;
    _viewOffset = 0.0;
    _isDragInProcess = false;
    _color = widget.color;

    _fadeoutAnimationController = AnimationController(
      vsync: this,
      duration: widget.scrollbarFadeDuration,
    );
    _fadeoutOpacityAnimation = CurvedAnimation(
      parent: _fadeoutAnimationController,
      curve: Curves.fastOutSlowIn,
    );

    _draggableScrollThumb = DraggableScrollThumb(
      color: _color,
      fadeoutOpacityAnimation: _fadeoutOpacityAnimation,
      builder: widget.scrollThumbBuilder,
      height: widget.heightScrollThumb,
      withDynamicLabel: widget.dynamicLabelTextBuilder != null,
    );

    _fadeoutAnimationController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _fadeoutAnimationController.dispose();
    _fadeoutTimer?.cancel();
    super.dispose();
  }

  double get barMaxScrollExtent =>
      context.size.height - widget.heightScrollThumb;

  double get barMinScrollExtent => 0.0;

  double get viewMaxScrollExtent => _controller.position.maxScrollExtent;

  double get viewMinScrollExtent => _controller.position.minScrollExtent;

  @override
  Widget build(BuildContext context) {
    String label;
    if (widget.dynamicLabelTextBuilder != null && _isDragInProcess) {
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
              child: _draggableScrollThumb.build(dynamicLabelText: label),
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
        if (_viewOffset < _controller.position.minScrollExtent) {
          _viewOffset = _controller.position.minScrollExtent;
        }
        if (_viewOffset > viewMaxScrollExtent) {
          _viewOffset = viewMaxScrollExtent;
        }
      }

      if (notification is ScrollUpdateNotification ||
          notification is OverscrollNotification) {
        if (_fadeoutAnimationController.status != AnimationStatus.forward) {
          _fadeoutAnimationController.forward();
        }

        _fadeoutTimer?.cancel();
        _fadeoutTimer = Timer(widget.scrollbarTimeToFade, () {
          _fadeoutAnimationController.reverse();
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
    });
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_fadeoutAnimationController.status != AnimationStatus.forward) {
      _fadeoutAnimationController.forward();
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

        _viewOffset = _controller.position.pixels + viewDelta;
        if (_viewOffset < _controller.position.minScrollExtent) {
          _viewOffset = _controller.position.minScrollExtent;
        }
        if (_viewOffset > viewMaxScrollExtent) {
          _viewOffset = viewMaxScrollExtent;
        }
        _controller.jumpTo(_viewOffset);
      }
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    _fadeoutTimer = Timer(widget.scrollbarTimeToFade, () {
      _fadeoutAnimationController.reverse();
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

class DraggableScrollThumb extends ChangeNotifier {
  DraggableScrollThumb({
    @required this.color,
    @required this.fadeoutOpacityAnimation,
    @required this.builder,
    @required this.height,
    this.withDynamicLabel = false,
  })  : assert(color != null),
        assert(fadeoutOpacityAnimation != null),
        assert(builder != null),
        assert(height != null);

  ///height of the thumb
  final double height;

  /// [Color] of the thumb. Mustn't be null.
  final Color color;

  /// An opacity [Animation] that dictates the opacity of the thumb.
  /// Changes in value of this [Listenable] will automatically trigger repaints.
  /// Mustn't be null.
  final Animation<double> fadeoutOpacityAnimation;

  final bool withDynamicLabel;

  final DraggableScrollThumbBuilder builder;

  Widget build({String dynamicLabelText}) {
    if (fadeoutOpacityAnimation.value == 0.0) {
      return Container();
    }

    return builder(
      color,
      fadeoutOpacityAnimation.value,
      height,
      dynamicLabelText: dynamicLabelText,
    );
  }

  @override
  void dispose() {
    super.dispose();
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
