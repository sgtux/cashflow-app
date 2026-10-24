class HomeDescriptionValue {
  final String description;
  final num value;

  /// Entrada de renda passiva (aluguel, dividendos, juros...).
  final bool isPassive;

  HomeDescriptionValue(
      {required this.description, required this.value, this.isPassive = false});

  factory HomeDescriptionValue.fromMap(Map<String, dynamic> map) {
    return HomeDescriptionValue(
        description: map['description'],
        value: map['value'],
        isPassive: map['isPassive'] ?? false);
  }
}
