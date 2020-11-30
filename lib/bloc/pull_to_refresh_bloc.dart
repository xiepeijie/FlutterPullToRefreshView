import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_to_refresh_view/dio_http.dart';
import 'package:pull_to_refresh_view/model.dart';

import 'model_state.dart';

class PullToRefreshBloc extends Cubit<ModelState> {

  PullToRefreshBloc() : super(ModelState([]));

  void add(ModelState state) {
    super.emit(state);
  }

  Future<void> getDataList() async {
    final apiPath = '/wxarticle/chapters/json';
    final data = await DioHttp.request<List<dynamic>>(
        apiPath,
        onError: (code, msg) {
          print('$code - $msg');
        }
    );
    if (data == null) {
      return state;
    }
    print("data <- " + data.toString());
    List<Model> models = data.map((e) => Model.fromJson(e)).toList();
    add(ModelState(models));
  }

}