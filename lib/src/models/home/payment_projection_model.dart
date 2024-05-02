class PaymentProjectionModel {
  final String description;
  final String? number;
  final int qtdInstallments;
  final DateTime? paidDate;
  final num value;
  final int type;
  final String creditCardName;
  final bool isIn;

  PaymentProjectionModel(
      {required this.description,
      required this.number,
      required this.qtdInstallments,
      required this.paidDate,
      required this.value,
      required this.isIn,
      required this.type,
      required this.creditCardName});

  factory PaymentProjectionModel.fromMap(Map<String, dynamic> map) {
    return PaymentProjectionModel(
        description: map['description'],
        number: map['number'],
        qtdInstallments: map['qtdInstallments'],
        paidDate:
            map['paidDate'] == null ? null : DateTime.parse(map['paidDate']),
        value: map['value'],
        type: map['type'],
        isIn: map['in'],
        creditCardName: map['creditCardName']);
  }
}
