import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';

import 'constants.dart';

/// Preferências locais do app: versão das telas que têm um novo visual (v2)
/// e o tema claro/escuro compartilhado por essas telas.
class AppSettings {
  static final ValueNotifier<int> loginVersion = ValueNotifier(1);
  static final ValueNotifier<int> projectionVersion = ValueNotifier(1);
  static final ValueNotifier<ThemeMode> themeModeV2 =
      ValueNotifier(ThemeMode.system);

  /// Deve ser chamado depois de `initLocalStorage()`.
  static void load() {
    loginVersion.value = _readVersion(loginVersionStorageKey);
    projectionVersion.value = _readVersion(projectionVersionStorageKey);
    themeModeV2.value =
        _parseThemeMode(localStorage.getItem(themeV2StorageKey));
  }

  static void setLoginVersion(int version) =>
      _setVersion(loginVersion, loginVersionStorageKey, version);

  static void setProjectionVersion(int version) =>
      _setVersion(projectionVersion, projectionVersionStorageKey, version);

  static void setThemeModeV2(ThemeMode mode) {
    themeModeV2.value = mode;
    localStorage.setItem(themeV2StorageKey, mode.toString());
  }

  /// Se as telas v2 devem usar o tema escuro, considerando o tema do sistema.
  static bool isDarkV2(BuildContext context) {
    final mode = themeModeV2.value;
    return mode == ThemeMode.dark ||
        (mode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
  }

  static void toggleThemeV2(BuildContext context) {
    setThemeModeV2(isDarkV2(context) ? ThemeMode.light : ThemeMode.dark);
  }

  static int _readVersion(String key) =>
      int.tryParse(localStorage.getItem(key) ?? '') ?? 1;

  static void _setVersion(ValueNotifier<int> notifier, String key, int value) {
    notifier.value = value;
    localStorage.setItem(key, value.toString());
  }

  static ThemeMode _parseThemeMode(String? value) {
    for (final mode in ThemeMode.values) {
      if (mode.toString() == value) return mode;
    }
    return ThemeMode.system;
  }
}
