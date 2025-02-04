class HomeDescriptionValue {
  final String description;
  final num value;

  HomeDescriptionValue({required this.description, required this.value});

  factory HomeDescriptionValue.fromMap(Map<String, dynamic> map) {
    return HomeDescriptionValue(
        description: map['description'], value: map['value']);
  }
}
