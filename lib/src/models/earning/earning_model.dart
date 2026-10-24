import 'package:cashflow_app/src/models/model_base.dart';

/// Tipo "Outros" da API, usado quando o ganho não tem tipo definido.
const int defaultEarningTypeId = 20;

/// Ganho avulso: freela, venda, bônus.
class EarningModel extends ModelBase {
  final int id;
  final String description;
  final double value;
  final DateTime date;
  final int type;
  final String? typeDescription;

  /// Renda passiva (aluguel, dividendos, juros...), calculada pela API.
  final bool isPassive;

  EarningModel(
      {required this.id,
      required this.description,
      required this.value,
      required this.date,
      this.type = defaultEarningTypeId,
      this.typeDescription,
      this.isPassive = false});

  factory EarningModel.fromMap(Map<String, dynamic> map) {
    return EarningModel(
        id: map['id'],
        description: map['description'] ?? '',
        value: asDouble(map['value']),
        date: asDate(map['date']) ?? DateTime.now(),
        type: map['type'] ?? defaultEarningTypeId,
        typeDescription: map['typeDescription'],
        isPassive: map['isPassive'] ?? false);
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'value': value,
      'date': date.toIso8601String(),
      'type': type
    };
  }
}
