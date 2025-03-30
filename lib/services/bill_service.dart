class BillService {
  static const Map<int, int> billDenominations = {
    100000: 10, // Cantidad de billetes disponibles
    50000: 20,
    20000: 30,
    10000: 40,
  };

  static Map<int, int> calculateBills(double amount) {
    if (!isValidAmount(amount)) {
      return {};
    }

    int targetAmount = amount.toInt();
    List<int> denominations = billDenominations.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    List<List<int>> matriz = [];
    int suma = 0;
    bool alcanzado = false;
    int total_rows = 0;

    while (!alcanzado) {
      // Crear fila con ceros hasta total_rows y el resto sin inicializar
      List<int> fila = [];
      for (int i = 0; i < total_rows; i++) {
        fila.add(0);
      }

      bool se_pudo_sumar = false;
      int suma_temporal = suma;

      // Llenar el resto de la fila desde total_rows
      for (int j = total_rows; j < denominations.length; j++) {
        if (suma_temporal + denominations[j] <= targetAmount) {
          fila.add(1);
          suma_temporal += denominations[j];
          se_pudo_sumar = true;

          if (suma_temporal == targetAmount) {
            alcanzado = true;
            suma = suma_temporal;
            break;
          }
        } else {
          fila.add(0);
        }
      }

      // Asegurarnos que la fila tenga la longitud correcta
      while (fila.length < denominations.length) {
        fila.add(0);
      }

      if (se_pudo_sumar || total_rows == 0) {
        suma = suma_temporal;
        matriz.add(fila);
      }

      // Verificar si necesitamos hacer acarreo
      if (!se_pudo_sumar) {
        if (total_rows < denominations.length - 1) {
          total_rows++;
        } else {
          if (matriz.isEmpty) {
            return {};
          }
          matriz.removeLast();
          if (matriz.isEmpty) {
            total_rows = 0;
          } else {
            total_rows = matriz.last.indexOf(1) + 1;
            suma = 0;
            for (var row in matriz) {
              for (int i = 0; i < row.length; i++) {
                if (row[i] == 1) {
                  suma += denominations[i];
                }
              }
            }
          }
        }
      } else {
        total_rows = 0;
      }
    }

    // Convertir la matriz a un mapa de billetes
    Map<int, int> result = Map.from(billDenominations);
    for (int i = 0; i < denominations.length; i++) {
      result[denominations[i]] = matriz.fold(0, (sum, row) => sum + row[i]);
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
