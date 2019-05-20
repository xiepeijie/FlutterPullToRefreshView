import 'package:flutter/material.dart';


typedef Builder = Widget Function(int index, dynamic itemData);


// The default insert/remove animation duration.
const Duration _duration = Duration(milliseconds: 300);


class LoadMoreListView<T> extends StatefulWidget {

  LoadMoreListView(List<T> list, Builder builder, {Key key, Widget loadMoreItem}) :
        _list = list,
        _builder = builder,
        _loadMoreItem = loadMoreItem,
        super(key: key);


  final List<T> _list;
  final Builder _builder;
  final Widget _loadMoreItem;

  @override
  State<StatefulWidget> createState() {
    return LoadMoreListViewState(_list, _builder, loadMoreItem: _loadMoreItem);
  }

}


class LoadMoreListViewState<T> extends State<LoadMoreListView> {

  LoadMoreListViewState(List<T> list, Builder builder, {Widget loadMoreItem}) :
        _list = list,
        _builder = builder,
        _loadMoreItem = loadMoreItem;


  static const String loadMore = '正在加载...';
  static const String noMore = '我是有底线的';

  final GlobalKey<AnimatedListState> _keyAnimatedList = new GlobalKey();
  final List<T> _list;
  final Builder _builder;
  final Widget _loadMoreItem;
  bool _canLoadMore = true;


  @override
  Widget build(BuildContext context) {
    return AnimatedList(key: _keyAnimatedList,
      itemBuilder: (context, index, animation) {
        bool bottomEdge = index == _list.length;
        T element;
        Widget childView;
        if (bottomEdge) {
          childView = new Card(
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
      initialItemCount: _list.isEmpty ? 0 : (_list.length + 1),
    );
  }

  Widget _buildLoadMoreItem() {
    double cpiSize = _canLoadMore ? 13.0 : 0.0;
    TextStyle style = TextStyle(color: Colors.black, fontSize: 15.0);
    String loadText = _canLoadMore ? loadMore : noMore;
    Widget item = _loadMoreItem;
    if (item == null) {
      item = SizedBox(
        height: 44.0,
        child: Row(mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
                padding: EdgeInsetsDirectional.only(end: 6),
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
