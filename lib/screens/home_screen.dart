import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/account.dart';
import 'create_account_screen.dart';
import 'withdrawal_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Cajero Automático',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn().slideY(begin: -0.2),
              const SizedBox(height: 40),
              _buildOptionCard(
                context,
                'Crear Nueva Cuenta',
                Icons.account_balance_wallet,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateAccountScreen(),
                  ),
                ),
              ).animate().fadeIn().slideX(begin: -0.2),
              const SizedBox(height: 20),
              _buildOptionCard(
                context,
                'Retiro Nequi',
                Icons.phone_android,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WithdrawalScreen(
                      accountType: AccountType.nequi,
                    ),
                  ),
                ),
              ).animate().fadeIn().slideX(begin: 0.2),
              const SizedBox(height: 20),
              _buildOptionCard(
                context,
                'Retiro Ahorro a la Mano',
                Icons.savings,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WithdrawalScreen(
                      accountType: AccountType.ahorroAMano,
                    ),
                  ),
                ),
              ).animate().fadeIn().slideX(begin: -0.2),
              const SizedBox(height: 20),
              _buildOptionCard(
                context,
                'Retiro Cuenta de Ahorros',
                Icons.account_balance,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WithdrawalScreen(
                      accountType: AccountType.cuentaAhorros,
                    ),
                  ),
                ),
              ).animate().fadeIn().slideX(begin: 0.2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(
                icon,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
