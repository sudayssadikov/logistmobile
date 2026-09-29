import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../storage/local_storage_service.dart';

enum AppLanguage {
  uz(code: 'uz', name: 'O\'zbekcha', flag: '🇺🇿', subTitle: 'Lotin alifbosida'),
  ru(code: 'ru', name: 'Русский', flag: '🇷🇺', subTitle: 'Русский язык'),
  en(code: 'en', name: 'English', flag: '🇬🇧', subTitle: 'International English');

  final String code;
  final String name;
  final String flag;
  final String subTitle;

  const AppLanguage({
    required this.code,
    required this.name,
    required this.flag,
    required this.subTitle,
  });

  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (lang) => lang.code == code.toLowerCase(),
      orElse: () => AppLanguage.uz,
    );
  }
}

class AppLocalizations {
  final Locale locale;
  static Map<String, dynamic> _localizedStrings = {};
  static AppLocalizations? _instance;

  AppLocalizations(this.locale) {
    _instance = this;
  }

  static AppLocalizations get instance => _instance ?? AppLocalizations(const Locale('uz'));

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ?? _instance;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  Future<bool> load() async {
    try {
      final jsonString = await rootBundle.loadString('assets/translations/${locale.languageCode}.json');
      _localizedStrings = json.decode(jsonString) as Map<String, dynamic>;
      return true;
    } catch (e) {
      debugPrint('Error loading translation for ${locale.languageCode}: $e');
      _localizedStrings = {};
      return false;
    }
  }

  String translate(String key, {Map<String, String>? args}) {
    final keys = key.split('.');
    dynamic value = _localizedStrings;

    for (final k in keys) {
      if (value is Map<String, dynamic> && value.containsKey(k)) {
        value = value[k];
      } else {
        return key; // Fallback to key if not found
      }
    }

    if (value is String) {
      var result = value;
      if (args != null) {
        args.forEach((k, v) {
          result = result.replaceAll('{$k}', v);
        });
      }
      return result;
    }

    return key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['uz', 'ru', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// Extension for fast translation on any String key
extension TranslationExtension on String {
  String tr({Map<String, String>? args}) {
    return AppLocalizations.instance.translate(this, args: args);
  }
}

// -------------------------------------------------------------
// Localization BLoC / Cubit for Instant In-App Switching
// -------------------------------------------------------------

abstract class LocalizationEvent {}

class ChangeLanguageEvent extends LocalizationEvent {
  final AppLanguage language;
  ChangeLanguageEvent(this.language);
}

class LoadSavedLanguageEvent extends LocalizationEvent {}

class LocalizationState {
  final AppLanguage language;
  final Locale locale;

  const LocalizationState({
    required this.language,
    required this.locale,
  });
}

class LocalizationBloc extends Bloc<LocalizationEvent, LocalizationState> {
  final ILocalStorageService _storage;

  LocalizationBloc({required ILocalStorageService storage})
      : _storage = storage,
        super(const LocalizationState(
          language: AppLanguage.uz,
          locale: Locale('uz'),
        )) {
    on<LoadSavedLanguageEvent>(_onLoadSavedLanguage);
    on<ChangeLanguageEvent>(_onChangeLanguage);
  }

  Future<void> _onLoadSavedLanguage(
    LoadSavedLanguageEvent event,
    Emitter<LocalizationState> emit,
  ) async {
    final savedCode = await _storage.getLanguage();
    final lang = AppLanguage.fromCode(savedCode);
    final locale = Locale(lang.code);
    await AppLocalizations(locale).load();
    emit(LocalizationState(language: lang, locale: locale));
  }

  Future<void> _onChangeLanguage(
    ChangeLanguageEvent event,
    Emitter<LocalizationState> emit,
  ) async {
    final locale = Locale(event.language.code);
    await _storage.saveLanguage(event.language.code);
    await AppLocalizations(locale).load();
    emit(LocalizationState(language: event.language, locale: locale));
  }
}
