class UzbekistanRegions {
  static const String toshkentShahar = 'Toshkent shahri';
  static const String toshkentViloyati = 'Toshkent viloyati';
  static const String samarqandViloyati = 'Samarqand viloyati';
  static const String fargonaViloyati = 'Farg\'ona viloyati';
  static const String andijonViloyati = 'Andijon viloyati';
  static const String namanganViloyati = 'Namangan viloyati';
  static const String buxoroViloyati = 'Buxoro viloyati';
  static const String qashqadaryoViloyati = 'Qashqadaryo viloyati';
  static const String surxondaryoViloyati = 'Surxondaryo viloyati';
  static const String xorazmViloyati = 'Xorazm viloyati';
  static const String jizzaxViloyati = 'Jizzax viloyati';
  static const String navoiyViloyati = 'Navoiy viloyati';
  static const String sirdaryoViloyati = 'Sirdaryo viloyati';
  static const String qoraqalpogiston = 'Qoraqalpog\'iston Respublikasi';

  static const List<String> all = [
    toshkentShahar,
    toshkentViloyati,
    samarqandViloyati,
    fargonaViloyati,
    andijonViloyati,
    namanganViloyati,
    buxoroViloyati,
    qashqadaryoViloyati,
    surxondaryoViloyati,
    xorazmViloyati,
    jizzaxViloyati,
    navoiyViloyati,
    sirdaryoViloyati,
    qoraqalpogiston,
  ];

  /// Nominatim yoki geocoderdan kelgan matnni rasmiy viloyat nomiga normallashtiradi
  static String normalizeRegion(String? raw, {String fallback = toshkentShahar}) {
    if (raw == null || raw.trim().isEmpty) return fallback;
    final lower = raw.toLowerCase().replaceAll("'", "").replaceAll("`", "");

    if (lower.contains('tashkent city') || lower.contains('город ташкент') || (lower.contains('toshkent') && !lower.contains('viloyat') && !lower.contains('область'))) {
      return toshkentShahar;
    }
    if (lower.contains('tashkent') || lower.contains('ташкент')) {
      return toshkentViloyati;
    }
    if (lower.contains('samarqand') || lower.contains('samarkand') || lower.contains('самарканд')) {
      return samarqandViloyati;
    }
    if (lower.contains('fargon') || lower.contains('fergana') || lower.contains('ферган')) {
      return fargonaViloyati;
    }
    if (lower.contains('andijon') || lower.contains('andijan') || lower.contains('андижан')) {
      return andijonViloyati;
    }
    if (lower.contains('namangan') || lower.contains('наманган')) {
      return namanganViloyati;
    }
    if (lower.contains('buxoro') || lower.contains('bukhara') || lower.contains('бухар')) {
      return buxoroViloyati;
    }
    if (lower.contains('qashqadaryo') || lower.contains('kashkadarya') || lower.contains('кашкадарь')) {
      return qashqadaryoViloyati;
    }
    if (lower.contains('surxondaryo') || lower.contains('surkhandarya') || lower.contains('сурхандарь')) {
      return surxondaryoViloyati;
    }
    if (lower.contains('xorazm') || lower.contains('khorezm') || lower.contains('хорезм')) {
      return xorazmViloyati;
    }
    if (lower.contains('jizzax') || lower.contains('jizzakh') || lower.contains('джизак')) {
      return jizzaxViloyati;
    }
    if (lower.contains('navoiy') || lower.contains('navoi') || lower.contains('навои')) {
      return navoiyViloyati;
    }
    if (lower.contains('sirdaryo') || lower.contains('syrdarya') || lower.contains('сырдарь')) {
      return sirdaryoViloyati;
    }
    if (lower.contains('qoraqalpoq') || lower.contains('karakalpak') || lower.contains('каракалпак')) {
      return qoraqalpogiston;
    }

    return fallback;
  }
}

