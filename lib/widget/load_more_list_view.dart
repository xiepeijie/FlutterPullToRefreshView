import 'package:flutter/material.dart';


typedef Builder = Widget Function(int index, dynamic itemData);


// The default insert/remove animation duration.
const Duration _duration = Duration(milliseconds: 300);


class LoadMoreListView<T> extends StatefulWidget {

  LoadMoreListView(List<T> list, Builder builder,
      {Key key, Widget loadMoreItem, String emptyImage, String emptyText = '暂无内容'}) :
        _list = list,
        _builder = builder,
        _loadMoreItem = loadMoreItem,
        _emptyImageAsset = emptyImage,
        _emptyText = emptyText,
        super(key: key);


  final List<T> _list;
  final Builder _builder;
  final Widget _loadMoreItem;
  final String _emptyImageAsset;
  final String _emptyText;

  @override
  State<StatefulWidget> createState() {
    return LoadMoreListViewState(
        _list, _builder,
        loadMoreItem: _loadMoreItem,
        emptyImage: _emptyImageAsset,
        emptyText: _emptyText
    );
  }

}


class LoadMoreListViewState<T> extends State<LoadMoreListView> {

  LoadMoreListViewState(List<T> list, Builder builder,
      {Widget loadMoreItem, String emptyImage, String emptyText}) :
        _list = list,
        _builder = builder,
        _loadMoreItem = loadMoreItem,
        _emptyImageAsset = emptyImage,
        _emptyText = emptyText;


  static const String loadMore = '正在加载...';
  static const String noMore = '我是有底线的';

  final GlobalKey<AnimatedListState> _keyAnimatedList = new GlobalKey();
  final List<T> _list;
  final Builder _builder;
  final Widget _loadMoreItem;
  bool _canLoadMore = true;

  double _emptyHeight = 0.0;
  String _emptyImageAsset;
  String _emptyText;

  set emptyImageAsset(String emptyImage) {
    _emptyImageAsset = emptyImage;
  }

  set emptyText(String emptyText) {
    _emptyText = emptyText;
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((d) {
      setState(() {
        double height = _keyAnimatedList.currentContext.size.height;
        _emptyHeight= height.clamp(200.0, 500.0);
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedList(key: _keyAnimatedList,
      itemBuilder: (context, index, animation) {
        if (_list.isEmpty) {
          return _buildEmptyView();
        }
        bool bottomEdge = index == _list.length;
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
          element = _list[index];
          childView = _builder(index, element);
        }
        return new SizeTransition(
          axis: Axis.vertical,
          sizeFactor: animation,
          child: childView,
        );
      },
      initialItemCount: _list.isEmpty ? 1 : (_list.length + 1),
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
    Widget item = _loadMoreItem;
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
                    strokeWidth: 2.0,
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

  void setCanLoadMore(bool canLoadMore) {
    _canLoadMore = canLoadMore;
  }

  void insertItem(int index, {Duration duration = _duration}) {
    _keyAnimatedList.currentState.insertItem(index, duration: duration);
  }

  void removeItem(int index, AnimatedListRemovedItemBuilder builder, {Duration duration = _duration}) {
    _keyAnimatedList.currentState.removeItem(index, builder, duration: duration);
  }
}
