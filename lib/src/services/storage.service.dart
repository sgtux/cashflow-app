import 'package:localstorage/localstorage.dart';
import 'package:cashflow_app/src/utils/constants.dart';

class StorageService {
  init() async {
    await initLocalStorage();
  }

  void setToken(String token) {
    localStorage.setItem(tokenStorageKey, token);
  }

  String? getToken() {
    return localStorage.getItem(tokenStorageKey);
  }
}
