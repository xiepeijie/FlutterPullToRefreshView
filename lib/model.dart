/// courseId : 13
/// id : 408
/// name : "鸿洋"
/// order : 190000
/// parentChapterId : 407
/// userControlSetTop : false
/// visible : 1

class Model {
  int _courseId;
  int _id;
  String _name;
  int _order;
  int _parentChapterId;
  bool _userControlSetTop;
  int _visible;

  int get courseId => _courseId;
  int get id => _id;
  String get name => _name;
  int get order => _order;
  int get parentChapterId => _parentChapterId;
  bool get userControlSetTop => _userControlSetTop;
  int get visible => _visible;

  Model({
      int courseId, 
      int id, 
      String name, 
      int order, 
      int parentChapterId, 
      bool userControlSetTop, 
      int visible}){
    _courseId = courseId;
    _id = id;
    _name = name;
    _order = order;
    _parentChapterId = parentChapterId;
    _userControlSetTop = userControlSetTop;
    _visible = visible;
}

  Model.fromJson(dynamic json) {
    _courseId = json["courseId"];
    _id = json["id"];
    _name = json["name"];
    _order = json["order"];
    _parentChapterId = json["parentChapterId"];
    _userControlSetTop = json["userControlSetTop"];
    _visible = json["visible"];
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["courseId"] = _courseId;
    map["id"] = _id;
    map["name"] = _name;
    map["order"] = _order;
    map["parentChapterId"] = _parentChapterId;
    map["userControlSetTop"] = _userControlSetTop;
    map["visible"] = _visible;
    return map;
  }

}