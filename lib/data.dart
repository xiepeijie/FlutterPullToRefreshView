
import 'base_model.dart';

class Data extends BaseModel {
  int id;
  String name;

  Data.fromJson(dynamic map) : super.fromJson(map) {
    id = map['id'];
    name = map['name'];
  }

  @override
  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}
