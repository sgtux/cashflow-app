class ResultModel {
  final List<String> errors;
  final dynamic data;

  ResultModel({required this.errors, required this.data});

  factory ResultModel.fromJson(dynamic json) {
    List<String> errors = [];
    final data = json.keys.contains('data') ? json['data'] : dynamic;

    if (json.keys.contains('errors')) {
      json['errors'].forEach((e) {
        errors.add(e);
      });
    }
    return ResultModel(data: data, errors: errors);
  }

  bool isValid() {
    return errors.isEmpty;
  }
}
