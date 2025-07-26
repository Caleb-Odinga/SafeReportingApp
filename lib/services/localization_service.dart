import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LocalizationService {
  final Locale locale;
  Map<String, String> _localizedStrings = {};
  
  LocalizationService(this.locale);
  
  static const supportedLocales = [
    Locale('en', 'US'),
    Locale('es', 'ES'),
    Locale('fr', 'FR'),
    Locale('ar', 'SA'),
    Locale('zh', 'CN'),
  ];
  
  static const LocalizationsDelegate<LocalizationService> delegate = _LocalizationServiceDelegate();
  
  static LocalizationService of(BuildContext context) {
    return Localizations.of<LocalizationService>(context, LocalizationService)!;
  }
  
  Future<void> load() async {
    String jsonString = await rootBundle.loadString('assets/i18n/${locale.languageCode}.json');
    Map<String, dynamic> jsonMap = json.decode(jsonString);
    _localizedStrings = jsonMap.map((key, value) => MapEntry(key, value.toString()));
  }
  
  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }
  
  static String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'en': return 'English';
      case 'es': return 'Español';
      case 'fr': return 'Français';
      case 'ar': return 'العربية';
      case 'zh': return '中文';
      default: return languageCode;
    }
  }
}

class _LocalizationServiceDelegate extends LocalizationsDelegate<LocalizationService> {
  const _LocalizationServiceDelegate();
  
  @override
  bool isSupported(Locale locale) {
    return LocalizationService.supportedLocales
        .map((e) => e.languageCode)
        .contains(locale.languageCode);
  }
  
  @override
  Future<LocalizationService> load(Locale locale) async {
    LocalizationService service = LocalizationService(locale);
    await service.load();
    return service;
  }
  
  @override
  bool shouldReload(_LocalizationServiceDelegate old) => false;
}
