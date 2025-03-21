import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/account.dart';
import '../services/account_service.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _pinController = TextEditingController();
  AccountType _selectedType = AccountType.nequi;

  @override
  void dispose() {
    _numberController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  String? _validateNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese un número';
    }

    switch (_selectedType) {
      case AccountType.nequi:
        if (!AccountService.validateNequiNumber(value)) {
          return 'El número debe tener 10 dígitos';
        }
        break;
      case AccountType.ahorroAMano:
        if (!AccountService.validateAhorroAManoNumber(value)) {
          return 'El número debe empezar con 0 o 1, seguido de 3 y 9 dígitos más';
        }
        break;
      case AccountType.cuentaAhorros:
        if (!AccountService.validateCuentaAhorrosNumber(value)) {
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

    switch (_selectedType) {
      case AccountType.nequi:
        if (value.length != 6) {
          return 'La clave debe tener 6 dígitos';
        }
        break;
      case AccountType.ahorroAMano:
      case AccountType.cuentaAhorros:
        if (value.length != 4) {
          return 'La clave debe tener 4 dígitos';
        }
        break;
    }

    return null;
  }

  Future<void> _createAccount() async {
    if (_formKey.currentState!.validate()) {
      final account = await AccountService.createAccount(
        number: _numberController.text,
        type: _selectedType,
        pin: _pinController.text,
      );

      if (account != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cuenta creada exitosamente'),
              backgroundColor: Color(0xFF28a745),
            ),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('El número de cuenta ya existe'),
              backgroundColor: Color(0xFFdc3545),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Nueva Cuenta'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<AccountType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Cuenta',
                  border: OutlineInputBorder(),
                ),
                items: AccountType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.toString().split('.').last),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                    _numberController.clear();
                    _pinController.clear();
                  });
                },
              ),
              const SizedBox(height: 20),
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
                    _selectedType == AccountType.nequi ? 10 : 11,
                  ),
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    final text = newValue.text;
                    if (text.isEmpty) return newValue;

                    switch (_selectedType) {
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
              ),
              const SizedBox(height: 20),
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
                    _selectedType == AccountType.nequi ? 6 : 4,
                  ),
                ],
                obscureText: true,
                validator: _validatePin,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _createAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text(
                  'Crear Cuenta',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
