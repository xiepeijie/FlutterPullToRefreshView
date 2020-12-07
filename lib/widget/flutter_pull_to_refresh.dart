library flutter_pull_to_refresh;

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';


/// pull to refresh view begin


typedef LoadMoreCallback = Future<void> Function({dynamic extra});


bool _canLoadMore = true;


class PullToRefreshView extends StatefulWidget {

  final Widget child;

  final RefreshCallback onRefresh;

  final LoadMoreCallback onLoadMore;

  const PullToRefreshView({
        Key key,
        @required this.child,
        this.onRefresh,
        this.onLoadMore
      }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return PullToRefreshState();
  }
}

class PullToRefreshState extends State<PullToRefreshView>
    with SingleTickerProviderStateMixin {
  final GlobalKey _keyIndicator = GlobalKey();

  static double _initTop = -80.0;
  double _top = _initTop;
  double _left = 0.0;

  double _dragOffset = 0.0;

  double _contentWidth;
  double _contentHeight;

  AnimationController _positionController;
  Animation<double> _value;
  Animation<Color> _valueColor;

  static final Animatable<double> _threeQuarterTween = Tween<double>(begin: 0.0, end: 0.75);

  bool _onRefreshing = false;
  bool _onLoading = false;

  static final _isIOS = Platform.isIOS;
  final millisecond = _isIOS ? 4 : 2;
  bool _isIOSScrollTop = false;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_frameCallback);

    _positionController = AnimationController(vsync: this);
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
        //print('load more complete');
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


/// load more list view begin


typedef Builder = Widget Function(int index, dynamic itemData);


// The default insert/remove animation duration.
const Duration _duration = Duration(milliseconds: 200);



class LoadMoreListView<T> extends StatefulWidget {

  LoadMoreListView(this.list, this.builder,
      {Key key, this.loadMoreItem, this.emptyImageAsset, String emptyText = '暂无内容', this.onPostBuild}) :
        emptyText = emptyText,
        super(key: key);

  final List<T> list;
  final Builder builder;
  final Widget loadMoreItem;
  final String emptyImageAsset;
  final String emptyText;
  final void Function() onPostBuild;


  @override
  State<StatefulWidget> createState() {
    return LoadMoreListViewState(list);
  }

}


class LoadMoreListViewState<T> extends State<LoadMoreListView> {

  static const String loadMore = '正在加载...';
  static const String noMore = '我是有底线的';

  final GlobalKey<AnimatedListState> _keyAnimatedList = new GlobalKey();

  final List<T> _list;

  double _emptyHeight = 0.0;
  String _emptyImageAsset;
  String _emptyText;

  bool _isBuild = false;


  LoadMoreListViewState(this._list);

  set emptyImageAsset(String emptyImage) {
    _emptyImageAsset = emptyImage;
  }

  set emptyText(String emptyText) {
    _emptyText = emptyText;
  }

  void setPersistentFrameListener(WidgetsBinding binding) {
    binding.addPersistentFrameCallback((timeStamp) {
      if (_isBuild) {
        _isBuild = false;
        widget.onPostBuild?.call();
      }
    });
  }

  @override
  void initState() {
    _emptyImageAsset = widget.emptyImageAsset;
    _emptyText = widget.emptyText;
    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((d) {
      setState(() {
        double height = _keyAnimatedList.currentContext.size.height;
        _emptyHeight = height.clamp(200.0, 500.0);
      });
      setPersistentFrameListener(binding);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _isBuild = true;
    return AnimatedList(key: _keyAnimatedList,
      itemBuilder: (context, index, animation) {
        if (widget.list.isEmpty) {
          return _buildEmptyView();
        }
        bool bottomEdge = index == widget.list.length;
        T element;
        Widget childView;
        if (bottomEdge) {
          childView = Card(
            color: Colors.transparent,
            elevation: 0.0,
            borderOnForeground: false,
            child: _buildLoadMoreItem(),
          );
        } else {
          element = widget.list[index];
          childView = widget.builder(index, element);
        }
        return new SlideTransition(
          //axis: Axis.vertical,
          position: Tween<Offset>(begin: Offset(0.0, 1.0), end: Offset.zero).animate(animation),
          child: childView,
        );
      },
      initialItemCount: 1,
    );
  }

  Widget _buildEmptyView() {
    List<Widget> children = <Widget>[Padding(padding: EdgeInsets.only(top: 10.0),
        child: Text(_emptyText, style: TextStyle(color: Colors.grey, fontSize: 16.0)))];
    if (_emptyImageAsset != null) {
      children.insert(0, Image.asset(_emptyImageAsset));
    }
    Column emptyView = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
    return SizedBox(width: double.infinity, height: _emptyHeight, child: emptyView);
  }

  Widget _buildLoadMoreItem() {
    double cpiSize = _canLoadMore ? 13.0 : 0.0;
    TextStyle style = TextStyle(fontSize: 15.0);
    String loadText = _canLoadMore ? loadMore : noMore;
    Widget item = widget.loadMoreItem;
    if (item == null) {
      item = SizedBox(
        height: 44.0,
        child: Row(mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
                padding: EdgeInsetsDirectional.only(end: 6.0),
                child: SizedBox(
                  width: cpiSize, height: cpiSize,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                  ),
                )
            ),
            Text(loadText, style: style),
          ],
        ),
      );
    }
    return item;
  }

  void insertItem(int index, {Duration duration = _duration}) {
    _keyAnimatedList.currentState.insertItem(index, duration: duration);
  }

  void insertItemValue(T value) {
    _list.add(value);
    insertItem(_list.length - 1);
  }

  void insertAllItem(List<T> list) {
    if (list == null || list.isEmpty) {
      return;
    }

    bool isEmpty = _list.isEmpty;
    list.forEach((value) {
      insertItemValue(value);
    });
    if (isEmpty) {
      insertItem(_list.length);
    }
  }

  AnimatedListRemovedItemBuilder _removedItemBuilder(Widget child) {
    AnimatedListRemovedItemBuilder removedItemBuilder = (context, animation) {
      return SlideTransition(
        position: Tween<Offset>(
        begin: Offset(1.2, 0.0), end: Offset(0.0, 0.0)).animate(animation),
        child: child
      );
    };
    return removedItemBuilder;
  }

  void removeItem(int index, {Widget child, AnimatedListRemovedItemBuilder builder, Duration duration = _duration}) {
    if (index > -1 && index < _list.length) {
      _list.removeAt(index);
    }
    builder = builder ?? (child != null ? _removedItemBuilder(child) : (context, animation) => SizedBox.shrink());
    _keyAnimatedList.currentState.removeItem(index, builder, duration: duration);
  }

  void removeAllItem(bool showEmptyView) {
    print('removeAllItem');
    int length = _list.length;
    _list.clear();
    for (int j = 0; j < length; ++j) {
      removeItem(0);
    }
    removeItem(0);
    if (showEmptyView) {
      insertItem(0);
    }
  }
}

