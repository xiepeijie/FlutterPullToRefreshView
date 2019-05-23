import 'dart:async';

import 'package:flutter/material.dart';
import 'http.dart';
import 'package:pull_to_refresh_view/widget/pull_to_refresh.dart';
import 'package:pull_to_refresh_view/widget/load_more_list_view.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    print('MyApp build');
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
          // This is the theme of your application.
          //
          // Try running your application with "flutter run". You'll see the
          // application has a blue toolbar. Then, without quitting the app, try
          // changing the primarySwatch below to Colors.green and then invoke
          // "hot reload" (press "r" in the console where you ran "flutter run",
          // or simply save your changes to "hot reload" in a Flutter IDE).
          // Notice that the counter didn't reset back to zero; the application
          // is not restarted.
          primarySwatch: Colors.blue),
      home: Scaffold(
        appBar: AppBar(title: Text('PullToRefresh'), centerTitle: true,),
        body: _PullToRefreshDemo(),
      ),
    );
  }
}



class _PullToRefreshDemo extends StatefulWidget {

  @override
  _PullToRefreshDemoState createState() {
    return _PullToRefreshDemoState();
  }

}


class _PullToRefreshDemoState extends State<_PullToRefreshDemo> {

  final GlobalKey<PullToRefreshState> _keyPullToRefresh = GlobalKey();

  final GlobalKey<LoadMoreListViewState> _keyLoadMore = new GlobalKey();

  final _bigFont = const TextStyle(fontSize: 18.0);

  final List<String> _list = List();

  final Http _http = Http();

  int i = 1;

  static const List<Color> colors = [Colors.white70, Colors.white54];

  @override
  void initState() {
    super.initState();
    //_onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    print('_PullToRefreshDemoState.build');
    return PullToRefreshView(
        key: _keyPullToRefresh,
        child: _buildWidget(),
        onRefresh: _onRefresh,
        onLoadMore: _onLoadMore,
    );
  }

  Widget _buildWidget() {
    return LoadMoreListView<String>(
        _list,
        (index, itemData) {
          //print("item = $index");
          return new Card(
            color: colors[index % colors.length],
            child: ListTile(title: Text(itemData, style: _bigFont))
          );
        },
        key: _keyLoadMore,
        // 自定义加载更多item的样式
        //loadMoreItem: Center(child: Text('Loading...')),
        emptyText: '暂时还没数据，试试下拉刷新',
    );
  }

  Future<void> _onRefresh() {
    i = 1;
    _keyPullToRefresh.currentState?.setCanLoadMore(true);
    _keyLoadMore.currentState?.setCanLoadMore(true);
    final Completer<void> completer = Completer<void>();
    Timer(const Duration(seconds: 1), () { completer.complete(); });
    return completer.future.then((v) {
      _loadDataFromHttp(true);
    });
  }

  Future<void> _onLoadMore({dynamic extra}) {
    final Completer<void> completer = Completer<void>();
    Timer(const Duration(seconds: 1), () { completer.complete(); });
    return completer.future.then((v) {
      _loadDataFromHttp(false);
    });
  }

  Future<void> _loadDataFromHttp(bool refresh) async {
    dynamic result = await _http.get();
    if (result == null) return;
    Duration duration = Duration(milliseconds: 400);
    bool isEmpty = _list.isEmpty;
    if (refresh) {
      final removeBuilder = (c, a) {};
      for (int j = 0; j < _list.length; ++j) {
        _keyLoadMore.currentState.removeItem(0, removeBuilder);
      }
      _keyLoadMore.currentState.removeItem(0, removeBuilder);
      _list.clear();
    }
    isEmpty = _list.isEmpty;
    List<dynamic> dataArray = result;
    dataArray.forEach((item) {
      _list.add("($i)${item['name']}");
      _keyLoadMore.currentState.insertItem(_list.length - 1, duration: duration);
      ++i;
    });
    if (isEmpty) {
      _keyLoadMore.currentState.insertItem(_list.length, duration: duration);
    }
    if (i > 40) {
      _keyPullToRefresh.currentState.setCanLoadMore(false);
      _keyLoadMore.currentState.setCanLoadMore(false);
    }
  }

}
