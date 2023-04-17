import 'package:localstorage/localstorage.dart';
import 'package:cashflow_app/src/utils/constants.dart';

class StorageService {
  late LocalStorage storage = LocalStorage(cashflowStorageKey);

  void setToken(String? token) {
    storage.setItem(tokenStorageKey, token);
  }

  String? getToken() {
    return storage.getItem(tokenStorageKey);
  }
}
