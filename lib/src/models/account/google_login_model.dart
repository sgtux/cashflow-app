import 'package:cashflow_app/src/models/model_base.dart';

class GoogleLoginModel extends ModelBase {
  final String idToken;

  GoogleLoginModel({required this.idToken});

  @override
  Map<String, dynamic> toMap() {
    return {'idToken': idToken};
  }
}
