import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account.dart';

class AccountService {
  static const String _storageKey = 'accounts';
  static List<Account> _accounts = [];

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final accountsJson = prefs.getStringList(_storageKey) ?? [];
    _accounts =
        accountsJson.map((json) => Account.fromJson(jsonDecode(json))).toList();
  }

  static Future<void> saveAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final accountsJson =
        _accounts.map((account) => jsonEncode(account.toJson())).toList();
    await prefs.setStringList(_storageKey, accountsJson);
  }

  static Future<Account?> createAccount({
    required String number,
    required AccountType type,
    required String pin,
  }) async {
    // Validar el número según el tipo de cuenta
    if (!_validateAccountNumber(number, type)) {
      return null;
    }

    // Validar la longitud del PIN según el tipo de cuenta
    if (!_validatePin(pin, type)) {
      return null;
    }

    if (_accounts.any((account) => account.number == number)) {
      return null;
    }

    final account = Account(
      number: number,
      type: type,
      pin: pin,
    );

    _accounts.add(account);
    await saveAccounts();
    return account;
  }

  static bool _validateAccountNumber(String number, AccountType type) {
    switch (type) {
      case AccountType.nequi:
        return number.length == 10 && number.startsWith('3');
      case AccountType.ahorroAMano:
        return number.length == 11 &&
            (number.startsWith('0') || number.startsWith('1')) &&
            number[1] == '3';
      case AccountType.cuentaAhorros:
        return number.length == 11;
    }
  }

  static bool _validatePin(String pin, AccountType type) {
    switch (type) {
      case AccountType.nequi:
        return pin.length == 6;
      case AccountType.ahorroAMano:
      case AccountType.cuentaAhorros:
        return pin.length == 4;
    }
  }

  static bool validateNequiNumber(String number) {
    return number.length == 10 && number.startsWith('3');
  }

  static bool validateAhorroAManoNumber(String number) {
    return number.length == 11 &&
        (number.startsWith('0') || number.startsWith('1')) &&
        number[1] == '3';
  }

  static bool validateCuentaAhorrosNumber(String number) {
    return number.length == 11;
  }

  static Account? getAccount(String number) {
    try {
      return _accounts.firstWhere((account) => account.number == number);
    } catch (e) {
      return null;
    }
  }

  static String generateTemporaryPin() {
    return (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString();
  }
}
