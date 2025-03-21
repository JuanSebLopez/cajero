import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/account.dart';
import '../services/account_service.dart';
import '../services/bill_service.dart';
import 'dart:async';

class WithdrawalScreen extends StatefulWidget {
  final AccountType accountType;

  const WithdrawalScreen({
    super.key,
    required this.accountType,
  });

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _pinController = TextEditingController();
  final _amountController = TextEditingController();
  String? _temporaryPin;
  bool _showTemporaryPin = false;
  bool _isAuthenticated = false;
  Account? _account;
  Map<int, int>? _billBreakdown;
  int _remainingSeconds = 60;
  Timer? _timer;

  @override
  void dispose() {
    _numberController.dispose();
    _pinController.dispose();
    _amountController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _remainingSeconds = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _showTemporaryPin = false;
          _temporaryPin = null;
          timer.cancel();
        }
      });
    });
  }

  String? _validateNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese un número';
    }

    switch (widget.accountType) {
      case AccountType.nequi:
        if (!value.startsWith('3') || value.length != 10) {
          return 'El número debe empezar con 3 y tener 10 dígitos';
        }
        break;
      case AccountType.ahorroAMano:
        if (!(value.startsWith('0') || value.startsWith('1')) ||
            value[1] != '3' ||
            value.length != 11) {
          return 'El número debe empezar con 0 o 1, seguido de 3 y tener 11 dígitos';
        }
        break;
      case AccountType.cuentaAhorros:
        if (value.length != 11) {
          return 'El número debe tener 11 dígitos';
        }
        break;
    }

    return null;
  }

  String? _validatePin(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese una clave';
    }

    if (widget.accountType == AccountType.nequi) {
      if (value != _temporaryPin) {
        return 'Clave temporal incorrecta';
      }
    } else {
      if (value != _account?.pin) {
        return 'Clave incorrecta';
      }
    }

    return null;
  }

  String? _validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese un monto';
    }

    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Por favor ingrese un monto válido';
    }

    if (amount <= 0) {
      return 'El monto debe ser mayor a 0';
    }

    if (amount % 1000 != 0) {
      return 'El monto debe ser múltiplo de 1000';
    }

    if (_account != null && amount > _account!.balance) {
      return 'Saldo insuficiente';
    }

    return null;
  }

  Future<void> _authenticate() async {
    if (_formKey.currentState!.validate()) {
      final account = AccountService.getAccount(_numberController.text);
      if (account == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cuenta no encontrada'),
              backgroundColor: Color(0xFFdc3545),
            ),
          );
        }
        return;
      }

      if (account.type != widget.accountType) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tipo de cuenta incorrecto'),
              backgroundColor: Color(0xFFdc3545),
            ),
          );
        }
        return;
      }

      setState(() {
        _account = account;
      });

      if (widget.accountType == AccountType.nequi && !_showTemporaryPin) {
        setState(() {
          _temporaryPin = AccountService.generateTemporaryPin();
          _showTemporaryPin = true;
        });
        _startTimer();
      }

      if (_pinController.text.isNotEmpty) {
        bool isValidPin = false;
        if (widget.accountType == AccountType.nequi) {
          isValidPin = _pinController.text == _temporaryPin;
        } else {
          isValidPin = _pinController.text == account.pin;
        }

        if (isValidPin) {
          setState(() {
            _isAuthenticated = true;
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Clave incorrecta'),
                backgroundColor: Color(0xFFdc3545),
              ),
            );
          }
        }
      }
    }
  }

  Future<void> _processWithdrawal() async {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text);
      if (_account!.validateWithdrawal(amount)) {
        final bills = BillService.calculateBills(amount);
        if (bills.isNotEmpty) {
          setState(() {
            _billBreakdown = bills;
          });
          _showWithdrawalResult();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'No se puede realizar el retiro con las denominaciones disponibles'),
                backgroundColor: Color(0xFFdc3545),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se puede realizar el retiro'),
              backgroundColor: Color(0xFFdc3545),
            ),
          );
        }
      }
    }
  }

  void _showWithdrawalResult() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Retiro Exitoso'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.accountType == AccountType.nequi) ...[
                  Text(
                    'Número para retiro: 0${_numberController.text}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                const Text(
                  'Desglose de Billetes:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                ..._billBreakdown!.entries.map((entry) {
                  if (entry.value > 0) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Text(
                        '${entry.value} billete(s) de \$${entry.key.toStringAsFixed(0)}',
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }).toList(),
                const SizedBox(height: 20),
                Text(
                  'Saldo restante: \$${_account!.balance.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  'Retiros posibles: ${(_account!.balance / double.parse(_amountController.text)).floor()}',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
                Navigator.of(context).pop(); // Vuelve a la pantalla anterior
              },
              child: const Text('Finalizar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Retiro ${widget.accountType.toString().split('.').last}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_isAuthenticated) ...[
                TextFormField(
                  controller: _numberController,
                  decoration: const InputDecoration(
                    labelText: 'Número de Cuenta',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(
                      widget.accountType == AccountType.nequi ? 10 : 11,
                    ),
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      final text = newValue.text;
                      if (text.isEmpty) return newValue;

                      switch (widget.accountType) {
                        case AccountType.nequi:
                          if (!text.startsWith('3')) {
                            return oldValue;
                          }
                          break;
                        case AccountType.ahorroAMano:
                          if (text.length >= 1 &&
                              !text.startsWith(RegExp(r'[01]'))) {
                            return oldValue;
                          }
                          if (text.length >= 2 && text[1] != '3') {
                            return oldValue;
                          }
                          break;
                        case AccountType.cuentaAhorros:
                          // No necesita validación especial
                          break;
                      }
                      return newValue;
                    }),
                  ],
                  validator: _validateNumber,
                  onChanged: (value) {
                    if (widget.accountType == AccountType.nequi &&
                        AccountService.validateNequiNumber(value) &&
                        !_showTemporaryPin) {
                      setState(() {
                        _temporaryPin = AccountService.generateTemporaryPin();
                        _showTemporaryPin = true;
                      });
                      _startTimer();
                    }
                  },
                ),
                const SizedBox(height: 20),
                if (_showTemporaryPin) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 15),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Tu clave temporal es:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _temporaryPin!,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Válida por $_remainingSeconds segundos',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                TextFormField(
                  controller: _pinController,
                  decoration: const InputDecoration(
                    labelText: 'Clave',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(
                      widget.accountType == AccountType.nequi ? 6 : 4,
                    ),
                  ],
                  obscureText: widget.accountType != AccountType.nequi,
                  validator: _validatePin,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Seleccione un monto:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 15),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildAmountButton(10000),
                    _buildAmountButton(20000),
                    _buildAmountButton(50000),
                    _buildAmountButton(100000),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'O ingrese otro monto:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Monto a Retirar',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      if (newValue.text.isEmpty) return newValue;
                      // Si el nuevo caracter es un 0, siempre permitirlo
                      if (newValue.text.length > oldValue.text.length &&
                          newValue.text.endsWith('0')) {
                        return newValue;
                      }
                      // Si no es un 0, validar que no haya más de 3 dígitos significativos
                      String significantDigits =
                          newValue.text.replaceAll(RegExp(r'0*$'), '');
                      if (significantDigits.length > 3) return oldValue;
                      return newValue;
                    }),
                  ],
                  validator: _validateAmount,
                ),
                const SizedBox(height: 20),
                if (_billBreakdown != null) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.accountType == AccountType.nequi) ...[
                          Text(
                            'Número para retiro: 0${_numberController.text}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        const Text(
                          'Desglose de Billetes:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_billBreakdown!.entries
                            .any((entry) => entry.value > 0)) ...[
                          ..._billBreakdown!.entries.map((entry) {
                            if (entry.value > 0) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 5),
                                child: Text(
                                  '${entry.value} billete(s) de \$${entry.key.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          }).toList(),
                        ] else ...[
                          const Text(
                            'No hay billetes disponibles para este monto',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.red,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        Text(
                          'Retiros posibles restantes: ${(_account!.balance / double.parse(_amountController.text)).floor()}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _authenticate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text(
                    'Autenticar',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ] else ...[
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Monto a Retirar',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      if (newValue.text.isEmpty) return newValue;
                      // Si el nuevo caracter es un 0, siempre permitirlo
                      if (newValue.text.length > oldValue.text.length &&
                          newValue.text.endsWith('0')) {
                        return newValue;
                      }
                      // Si no es un 0, validar que no haya más de 3 dígitos significativos
                      String significantDigits =
                          newValue.text.replaceAll(RegExp(r'0*$'), '');
                      if (significantDigits.length > 3) return oldValue;
                      return newValue;
                    }),
                  ],
                  validator: _validateAmount,
                ),
                const SizedBox(height: 20),
                if (_billBreakdown != null) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.accountType == AccountType.nequi) ...[
                          Text(
                            'Número para retiro: 0${_numberController.text}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        const Text(
                          'Desglose de Billetes:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_billBreakdown!.entries
                            .any((entry) => entry.value > 0)) ...[
                          ..._billBreakdown!.entries.map((entry) {
                            if (entry.value > 0) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 5),
                                child: Text(
                                  '${entry.value} billete(s) de \$${entry.key.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          }).toList(),
                        ] else ...[
                          const Text(
                            'No hay billetes disponibles para este monto',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.red,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        Text(
                          'Retiros posibles restantes: ${(_account!.balance / double.parse(_amountController.text)).floor()}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _processWithdrawal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text(
                    'Procesar Retiro',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountButton(double amount) {
    final formattedAmount = '\$${amount.toStringAsFixed(0)}';
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _amountController.text = amount.toString();
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        foregroundColor: Theme.of(context).colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
      child: Text(
        formattedAmount,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
