import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logiflow_mobile/core/localization/app_localizations.dart';
import 'package:logiflow_mobile/core/storage/local_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Localization & Multi-Language Tests', () {
    late ILocalStorageService storage;
    late LocalizationBloc localizationBloc;

    setUp(() {
      storage = LocalStorageService();
      localizationBloc = LocalizationBloc(storage: storage);
    });

    tearDown(() {
      localizationBloc.close();
    });

    test('AppLanguage parses supported codes accurately', () {
      expect(AppLanguage.fromCode('uz'), AppLanguage.uz);
      expect(AppLanguage.fromCode('ru'), AppLanguage.ru);
      expect(AppLanguage.fromCode('en'), AppLanguage.en);
      expect(AppLanguage.fromCode('invalid'), AppLanguage.uz); // Default fallback
    });

    test('LocalizationBloc initial state is Uzbek', () {
      expect(localizationBloc.state.language, AppLanguage.uz);
      expect(localizationBloc.state.locale, const Locale('uz'));
    });

    test('Changing language updates state and persists code', () async {
      localizationBloc.add(ChangeLanguageEvent(AppLanguage.ru));
      await expectLater(
        localizationBloc.stream,
        emits(isA<LocalizationState>().having(
          (s) => s.language,
          'language',
          AppLanguage.ru,
        )),
      );

      final savedLang = await storage.getLanguage();
      expect(savedLang, 'ru');
    });

    test('Changing to English updates state and persists code', () async {
      localizationBloc.add(ChangeLanguageEvent(AppLanguage.en));
      await expectLater(
        localizationBloc.stream,
        emits(isA<LocalizationState>().having(
          (s) => s.language,
          'language',
          AppLanguage.en,
        )),
      );

      final savedLang = await storage.getLanguage();
      expect(savedLang, 'en');
    });
  });
}
