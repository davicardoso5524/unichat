import 'package:flutter/material.dart';

/// Controller de tema (claro/escuro) do app.
class ThemeController extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  bool get estaEmModoEscuro => _themeMode == ThemeMode.dark;

  ThemeMode get modoTema => _themeMode;

  void alternarTema() {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }

  void definirModoTema(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}
