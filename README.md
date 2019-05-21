# FlutterPullToRefreshView

Flutter版的下拉刷新控件，且支持上滑至底部自动加载更多


## Screenshot

![](screen/screenshot.gif)


## Core code

控件核心代码2个dart文件：  
1、widget/pull_to_refresh.dart  
2、widget/load_more_list_view.dart  


## Usage

控件基本用法的关键代码如下：

```
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
    return LoadMoreListView<String>(_list,
        (index, itemData) {
          //print("item = $index");
          return new Card(
            color: colors[index % colors.length],
            child: ListTile(title: Text(itemData, style: _bigFont))
          );
        },
        key: _keyLoadMore);
  }
```

详细使用示例请阅读main.dart  


## Exist Problem

1、下拉刷新交互效果在iOS上体验较差，在Android上体验还不错，后续想办法优化在iOS上的体验  


## About me

微博：[@萧雾宇](http://weibo.com/payge)  


## License

MIT License，详细内容请查看LICENSE文件


