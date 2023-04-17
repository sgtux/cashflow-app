class HomeDataModel {
  final int index;
  final String description;
  final num value;

  HomeDataModel(
      {required this.index, required this.description, required this.value});

  factory HomeDataModel.fromMap(Map<String, dynamic> map) {
    return HomeDataModel(
        index: map['index'],
        description: map['description'],
        value: map['value']);
  }
}
