
import 'package:json_annotation/json_annotation.dart';

part 'data.g.dart';



@JsonSerializable()
class Data {
  int id;
  String name;

  Data(this.id, this.name);

  factory Data.fromJson(Map<String, dynamic> json) => _$DataFromJson(json);

  Map<String, dynamic> toJson() => _$DataToJson(this);
}
