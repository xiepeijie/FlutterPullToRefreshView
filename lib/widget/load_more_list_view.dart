import 'package:flutter/material.dart';


typedef Builder = Widget Function(int index, dynamic itemData);


// The default insert/remove animation duration.
const Duration _duration = Duration(milliseconds: 300);


class LoadMoreListView<T> extends StatefulWidget {

  LoadMoreListView(List<T> list, Builder builder, {Key key}) :
        _list = list,
         _builder = builder,
        super(key: key);


  final List<T> _list;
  final Builder _builder;

  @override
  State<StatefulWidget> createState() {
    return LoadMoreListViewState(_list, _builder);
  }

}


class LoadMoreListViewState<T> extends State<LoadMoreListView> {

  LoadMoreListViewState(List<T> list, Builder builder) :
        _list = list,
        _builder = builder;


  static const String loadMore = '正在加载...';
  static const String noMore = '我是有底线的';

  final GlobalKey<AnimatedListState> _keyAnimatedList = new GlobalKey();
  final List<T> _list;
  final Builder _builder;
  bool _canLoadMore = true;


  @override
  Widget build(BuildContext context) {
    return AnimatedList(key: _keyAnimatedList,
      itemBuilder: (context, index, animation) {
        bool bottomEdge = index == _list.length;
        TextStyle style;
        T element;
        Widget childView;
        if (bottomEdge) {
          style = TextStyle(color: Colors.black, fontSize: 15.0);
          String loadText = _canLoadMore ? loadMore : noMore;
          childView = new Card(
            color: Colors.transparent,
            elevation: 0.0,
            borderOnForeground: false,
            child: new SizedBox(
              height: 44.0,
              child: new Center(
                child: new Text(loadText, style: style),
              ),
            ),
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
