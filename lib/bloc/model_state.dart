import 'package:pull_to_refresh_view/model.dart';

class ModelState {
  final bool isRefresh;
  final List<Model> models;

  ModelState(this.isRefresh, this.models);
}