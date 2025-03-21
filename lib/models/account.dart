enum AccountType { nequi, ahorroAMano, cuentaAhorros }

class Account {
  final String number;
  final AccountType type;
  final String pin;
  double balance;

  Account({
    required this.number,
    required this.type,
    required this.pin,
    this.balance = 10000000, // Balance inicial de 10 millones
  });

  bool validateWithdrawal(double amount) {
    if (amount % 5000 == 0 && amount <= balance) {
      balance -= amount;
      return true;
    }
    return false;
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'type': type.toString(),
      'pin': pin,
      'balance': balance,
    };
  }

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      number: json['number'],
      type: AccountType.values.firstWhere((e) => e.toString() == json['type']),
      pin: json['pin'],
      balance: json['balance'],
    );
  }
}
