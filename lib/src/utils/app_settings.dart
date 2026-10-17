import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';

import 'constants.dart';

/// Preferências locais do app: versão da tela de login e tema do login v2.
class AppSettings {
  static final ValueNotifier<int> loginVersion = ValueNotifier(1);
  static final ValueNotifier<ThemeMode> loginThemeMode =
      ValueNotifier(ThemeMode.system);

  /// Deve ser chamado depois de `initLocalStorage()`.
  static void load() {
    loginVersion.value =
        int.tryParse(localStorage.getItem(loginVersionStorageKey) ?? '') ?? 1;
    loginThemeMode.value =
        _parseThemeMode(localStorage.getItem(loginThemeStorageKey));
  }

  static void setLoginVersion(int version) {
    loginVersion.value = version;
    localStorage.setItem(loginVersionStorageKey, version.toString());
  }

  static void setLoginThemeMode(ThemeMode mode) {
    loginThemeMode.value = mode;
    localStorage.setItem(loginThemeStorageKey, mode.toString());
  }

  static ThemeMode _parseThemeMode(String? value) {
    for (final mode in ThemeMode.values) {
      if (mode.toString() == value) return mode;
    }
    return ThemeMode.system;
  }
}
