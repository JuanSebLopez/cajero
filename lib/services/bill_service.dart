class BillService {
  static const Map<int, int> billDenominations = {
    100000: 10, // Cantidad de billetes disponibles
    50000: 20,
    20000: 30,
    10000: 40,
    2000: 50,
    1000: 100,
  };

  static Map<int, int> calculateBills(double amount) {
    if (!isValidAmount(amount)) {
      return {};
    }

    int targetAmount = amount.toInt();
    List<int> denominations = billDenominations.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    Map<int, int> result = Map.from(billDenominations);

    for (var denomination in denominations) {
      int numBills = targetAmount ~/ denomination;
      // Limitar al número de billetes disponibles
      numBills = numBills > billDenominations[denomination]!
          ? billDenominations[denomination]!
          : numBills;
      result[denomination] = numBills;
      targetAmount -= numBills * denomination;
    }

    // Si no se pudo completar el monto exacto, retornar vacío
    if (targetAmount > 0) {
      return {};
    }

    return result;
  }

  static bool isValidAmount(double amount) {
    // El monto debe ser positivo
    if (amount <= 0) return false;

    // El monto debe ser múltiplo de 1000
    if (amount % 1000 != 0) return false;

    return true;
  }

  static String formatAmount(double amount) {
    return '\$${amount.toStringAsFixed(0)}';
  }
}
