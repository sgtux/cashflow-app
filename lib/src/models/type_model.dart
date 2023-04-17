import 'package:cashflow_app/src/models/model_base.dart';

class TypeModel extends ModelBase {
  final int id;
  final String description;

  TypeModel({required this.id, required this.description});

  factory TypeModel.fromMap(Map<String, dynamic> map) {
    return TypeModel(id: map['id'], description: map['description']);
  }

  @override
  Map<String, dynamic> toMap() {
    return {'id': id, 'description': description};
  }
}
