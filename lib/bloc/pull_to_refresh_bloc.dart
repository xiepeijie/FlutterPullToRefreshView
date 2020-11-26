import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_to_refresh_view/dio_http.dart';
import 'package:pull_to_refresh_view/model.dart';

import 'ModelState.dart';

class PullToRefreshBloc extends Bloc<String, ModelState> {

  PullToRefreshBloc() : super(ModelState([]));

  @override
  Stream<ModelState> mapEventToState(String event) async* {
    ModelState modelState = await _getDataList();
    yield modelState;
  }

  Future<ModelState> _getDataList() async {
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
    return ModelState(models);
  }

}