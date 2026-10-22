import 'package:cashflow_app/src/models/model_base.dart';

class CreditCardModel extends ModelBase {
  final int id;
  final String name;

  CreditCardModel({required this.id, required this.name});

  factory CreditCardModel.fromMap(Map<String, dynamic> map) {
    return CreditCardModel(id: map['id'], name: map['name']);
  }

  @override
  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }
}
