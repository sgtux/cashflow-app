import 'package:cashflow_app/src/models/model_base.dart';

/// Ganho avulso: freela, venda, bônus.
class EarningModel extends ModelBase {
  final int id;
  final String description;
  final double value;
  final DateTime date;

  EarningModel(
      {required this.id,
      required this.description,
      required this.value,
      required this.date});

  factory EarningModel.fromMap(Map<String, dynamic> map) {
    return EarningModel(
        id: map['id'],
        description: map['description'] ?? '',
        value: asDouble(map['value']),
        date: asDate(map['date']) ?? DateTime.now());
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'value': value,
      'date': date.toIso8601String()
    };
  }
}
