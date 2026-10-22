import 'package:cashflow_app/src/models/model_base.dart';

class HouseholdExpenseModel extends ModelBase {
  final int id;
  final String description;
  final double value;
  final DateTime date;
  late int? vehicleId;
  late int type;
  late String? typeDescription;
  final int? creditCardId;
  final String? creditCardName;

  HouseholdExpenseModel(
      {required this.id,
      required this.description,
      required this.value,
      required this.date,
      required this.type,
      this.vehicleId,
      this.typeDescription,
      this.creditCardId,
      this.creditCardName});

  factory HouseholdExpenseModel.fromMap(Map<String, dynamic> map) {
    return HouseholdExpenseModel(
        id: map['id'],
        description: map['description'],
        value: map['value'],
        date: DateTime.parse(map['date']),
        type: map['type'],
        vehicleId: map['vehicleId'],
        typeDescription: map['typeDescription'],
        creditCardId: map['creditCardId'],
        creditCardName: map['creditCardName']);
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'value': value,
      'date': date.toIso8601String(),
      'type': type,
      'vehicleId': vehicleId,
      'creditCardId': creditCardId
    };
  }
}
