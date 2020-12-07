import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_to_refresh_view/bloc/pull_to_refresh_bloc.dart';
import 'package:pull_to_refresh_view/dio_http.dart';
import 'package:pull_to_refresh_view/model.dart';

import 'bloc/model_state.dart';
import 'widget/flutter_pull_to_refresh.dart';


void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    print('MyApp.build');
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
      home: _buildBlocProvider(),
    );
  }

  Widget _buildBlocProvider() {
    return BlocProvider<PullToRefreshBloc>(
      create: (context) => PullToRefreshBloc(),
      child: _PullToRefreshDemo(),
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

  static const List<Color> colors = [Color(0xFFf9f9f9), Color(0xFFEEEEEE)];

  final GlobalKey<PullToRefreshState> _keyPullToRefresh = GlobalKey();

  final GlobalKey<LoadMoreListViewState> _keyLoadMore = GlobalKey();

  final _bigFont = const TextStyle(fontSize: 18.0);

  final List<Model> _list = List();

  int i = 1;

  PullToRefreshBloc _bloc;


  @override
  void initState() {
    super.initState();
    _bloc = BlocProvider.of<PullToRefreshBloc>(context);
    _onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    print('_PullToRefreshDemoState.build');
    return Scaffold(
      appBar: AppBar(
        title: Text('PullToRefresh'),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              _clearList(true);
            }
          )
        ],
      ),
      body: PullToRefreshView(
        key: _keyPullToRefresh,
        child: _buildWidget(),
        onRefresh: _onRefresh,
        onLoadMore: _onLoadMore,
      ),
    );
  }

  Widget _buildWidget() {
    Widget widget = BlocBuilder<PullToRefreshBloc, ModelState>(
      builder: (context, state) {
        return LoadMoreListView<Model>(
          _list,
          (index, itemData) {
            //print("item = $index");
            Model itemModel = itemData as Model;
            Column column = Column(children: <Widget>[]);
            Widget itemChild = Container(
                height: 64.0,
                child: ListTile(title: Text('$index.${itemModel.name}', style: _bigFont))
            );
            column.children.add(itemChild);
            //column.children.add(Divider(color: Color(0xFF999999), height: 2.0));
            return Material(
                color: colors[index % colors.length],
                child: InkWell(
                    onTap: () {
                      _keyLoadMore.currentState.removeItem(
                          index,
                          child: itemChild,
                          duration: Duration(milliseconds: 500)
                      );
                    },
                    child: column
                )
            );
          },
          key: _keyLoadMore,
          // 自定义加载更多item的样式
          //loadMoreItem: Center(child: Text('Loading...')),
          emptyText: '暂时还没数据，试试下拉刷新',
          onPostBuild: () {
            print('onPostBuild');
            List<Model> result = state.models;
            if (result == null || result.isEmpty) return;

            if (state.isRefresh) {
              _clearList(false);
            }

            _keyLoadMore.currentState.insertAllItem(result);
            i += result.length;

            if (i > 40) {
              _keyPullToRefresh.currentState.setCanLoadMore(false);
            }
          },
        );
      },
    );
    return widget;
  }

  void _clearList(bool showEmptyView) {
    _keyLoadMore.currentState.removeAllItem(showEmptyView);
  }

  Future<void> _onRefresh() {
    i = 1;
    _keyPullToRefresh.currentState?.setCanLoadMore(true);
    final Completer<void> completer = Completer<void>();
    Timer(const Duration(seconds: 1), () { completer.complete(); });
    return completer.future.then((v) {
      // _requestData(true);
      _bloc.getDataList(true);
    });
  }

  Future<void> _onLoadMore({dynamic extra}) {
    final Completer<void> completer = Completer<void>();
    Timer(const Duration(seconds: 1), () { completer.complete(); });
    return completer.future.then((v) {
      // _requestData(false);
      _bloc.getDataList(false);
    });
  }

  void _requestData(bool refresh) async {
     final data = await DioHttp.request<List<dynamic>>('/wxarticle/chapters/json',
        onError: (error, errorMsg) {
          print('$error, $errorMsg');
        });
     if (data == null) return;

     print("data <- " + data.toString());
     List<Model> result = data.map((e) => Model.fromJson(e)).toList();
     if (result == null) return;

     if (refresh) {
       _clearList(false);
     }

     bool isEmpty = _list.isEmpty;

     result.forEach((item) {
       _list.add(item);
       _keyLoadMore.currentState.insertItem(_list.length - 1);
       ++i;
     });
     if (isEmpty) {
       _keyLoadMore.currentState.insertItem(_list.length);
     }
     if (i > 40) {
       _keyPullToRefresh.currentState.setCanLoadMore(false);
     }
  }

}
