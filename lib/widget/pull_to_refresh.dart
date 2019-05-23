import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

typedef LoadMoreCallback = Future<void> Function({dynamic extra});

class PullToRefreshView extends StatefulWidget {
  //final GlobalKey<PullToRefreshState> key;

  final Widget child;

  final RefreshCallback onRefresh;

  final LoadMoreCallback onLoadMore;

  const PullToRefreshView(
      {Key key, @required this.child, this.onRefresh, this.onLoadMore})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return PullToRefreshState();
  }
}

class PullToRefreshState extends State<PullToRefreshView>
    with SingleTickerProviderStateMixin {
  final GlobalKey _keyIndicator = GlobalKey();

  static double _initTop = -80.0;
  double _top = _initTop; //距顶部的偏移
  double _left = 0.0; //距左边的偏移

  double _dragOffset = 0.0;

  double _contentWidth;
  double _contentHeight;

  AnimationController _positionController;
  Animation<double> _value;
  Animation<Color> _valueColor;

  static final Animatable<double> _threeQuarterTween = Tween<double>(begin: 0.0, end: 0.75);

  bool _onRefreshing = false;
  bool _onLoading = false;
  bool _canLoadMore = true;

  static final _isIOS = Platform.isIOS;
  final millisecond = _isIOS ? 4 : 2;
  bool _isIOSScrollTop = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_frameCallback);

    _positionController = AnimationController(vsync: this);
    //_positionFactor = _positionController.drive(_kDragSizeFactorLimitTween);
    // The "value" of the circular progress indicator during a drag.
    _value = _positionController.drive(_threeQuarterTween);
  }

  @override
  void didChangeDependencies() {
    final ThemeData theme = Theme.of(context);
    _valueColor = _positionController.drive(ColorTween(
              begin: (theme.accentColor).withOpacity(0.0),
              end: (theme.accentColor).withOpacity(1.0))
          .chain(CurveTween(curve: const Interval(0.0, 1.0 / 1.5))),
    );
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _positionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildWidget();
  }

  bool canLoadMore() {
    return _canLoadMore;
  }

  void setCanLoadMore(bool canLoadMore) {
    _canLoadMore = canLoadMore;
  }

  void _frameCallback(Duration duration) {
    setState(() {
      _top = _initTop = -_keyIndicator.currentContext.size.height;
      _left = context.size.width / 2 - 20;
      _contentWidth = context.size.width;
      _contentHeight = context.size.height;
    });
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      //print('start');
      _dragOffset = 0.0;
      if (_isIOS) {
        _isIOSScrollTop = notification.metrics.pixels == 0;
      }
    }

    if (notification is ScrollUpdateNotification) {
      if (notification.metrics.pixels > 0.0) {
        if (_top > _initTop) {
          setState(() {
            _top -= notification.scrollDelta;
            if (_top <= _initTop) {
              _top = _initTop;
            }
          });

          _dragOffset -= notification.scrollDelta;
          double newValue = _dragOffset / (notification.metrics.viewportDimension * 0.25);
          _positionController.value = newValue.clamp(0.0, 1.0);
        } else if (notification.metrics.atEdge
            && notification.metrics.maxScrollExtent > 0.0) {
          _loadMore();
        }
        return false;
      } else if (_isIOSScrollTop) {
        _checkDragOffset(notification);
      }
    }

    if (notification is OverscrollNotification) {
      if (notification.overscroll > 0.0) {
        if (notification.overscroll > 0.5
            && notification.metrics.maxScrollExtent > 0.0) {
          _loadMore();
        }
      } else {
        _checkDragOffset(notification);
      }
    }

    if (notification is ScrollEndNotification) {
      //print('end');
      if (_top > 30) {
        Timer.periodic(Duration(milliseconds: millisecond), (timer) {
            //print('定时器Timer在Android和iOS平台上，回调函数执行的频率不同，导致下拉刷新回弹效果有差异');
            if (_top > 30) {
              setState(() {
                _top -= 1.3;
              });
            } else {
              timer.cancel();
              _refresh();
            }
        });
      } else {
        _reset();
      }
    }

    return false;
  }

  bool _handleGlowNotification(OverscrollIndicatorNotification notification) {
    //print('_handleGlowNotification');
    if (_canLoadMore) {
      notification.disallowGlow();
      return true;
    } else if (notification.leading) {
      notification.disallowGlow();
      return true;
    }
    return false;
  }

  void _checkDragOffset(ScrollNotification notification) {
    double dy;
    if (notification is ScrollUpdateNotification) {
      setState(() {
        dy = notification.scrollDelta * 1.6;
        dy = dy.clamp(-5.0, 0.0);
        //print("update dy = $dy");
        _top -= dy;
        _top = math.min(_top, 100);
      });

      _dragOffset -= math.min(notification.scrollDelta, 0.0);
    } else if (notification is OverscrollNotification) {
      setState(() {
        dy = notification.overscroll / 2.0;
        dy = dy.clamp(-3.0, -1.3);
        //print("over dy = $dy");
        _top -= dy;
        _top = math.min(_top, 100);
      });

      _dragOffset -= notification.overscroll / 2.0;
    }
    double newValue = _dragOffset / (notification.metrics.viewportDimension * 0.25);
    _positionController.value = newValue.clamp(0.0, 1.0);
  }

  void _refresh() {
    if (_onRefreshing) {
      return;
    }
    if (_isIOS) {
      _positionController.duration = Duration(milliseconds: 600);
      _positionController.repeat();
    } else {
      setState(() {});
    }
    _onRefreshing = true;

    Future<void> refreshResult = widget.onRefresh();
    refreshResult.whenComplete(() {
      _onRefreshing = false;
      _reset();
    });
  }

  void _loadMore() {
    if (_canLoadMore && !_onLoading && widget.onLoadMore != null) {
      _onLoading = true;
      widget.onLoadMore().whenComplete(() {
        print('load more complete');
        _onLoading = false;
      });
    }
  }

  void _reset() {
    _positionController.stop();
    if (_top > _initTop) {
      Timer.periodic(Duration(milliseconds: millisecond), (timer) {
          if (_top > _initTop) {
            setState(() {
              _top -= 1.3;
            });
          } else {
            timer.cancel();
            _top = _initTop;
            _dragOffset = 0.0;
            //_positionController.value = 0.0;
          }
      });
    } else {
      _top = _initTop;
      _dragOffset = 0.0;
      //_positionController.value = 0.0;
    }
  }

  Widget _buildWidget() {
    final Widget notificationChild = NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: NotificationListener<OverscrollIndicatorNotification>(
            onNotification: _handleGlowNotification,
            child: Positioned(
              top: _top - _initTop,
              left: 0,
              width: _contentWidth ?? 600,
              height: _contentHeight ?? 800,
              child: widget.child,
            )));

    return Stack(
      children: <Widget>[
        Container(
          color: Colors.white,
        ),
        notificationChild,
        Positioned(
          top: _top,
          left: _left,
          child: Container(
            key: _keyIndicator,
            padding: EdgeInsets.only(bottom: 20.0),
            alignment: Alignment.topCenter,
            child: AnimatedBuilder(
              animation: _positionController,
              builder: (BuildContext context, Widget child) {
                return RefreshProgressIndicator(
                  value: _isIOS ? _value.value : (_onRefreshing ? null : _value.value),
                  valueColor: _valueColor,
                  backgroundColor: Colors.white70,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
