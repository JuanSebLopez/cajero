# Cajero Automático

Una aplicación Flutter que simula un cajero automático con tres tipos de retiros diferentes.

## Características

- Tres tipos de retiros:
  1. Retiro por número de celular estilo NEQUI
  2. Retiro estilo ahorro a la mano
  3. Retiro por cuenta de ahorros

### Validaciones

- **Retiro NEQUI**:
  - Número de 10 dígitos
  - Clave temporal de 6 dígitos visible por 60 segundos
  - Reporte con número de 11 dígitos (0 + número original)

- **Ahorro a la Mano**:
  - Número de 11 dígitos empezando por 0 o 1
  - Segundo dígito debe ser 3
  - Clave de 4 dígitos oculta

- **Cuenta de Ahorros**:
  - Número de 11 dígitos
  - Clave de 4 dígitos oculta

### Restricciones

- No se permiten retiros que incluyan billetes de 5,000 pesos
- Los montos deben ser múltiplos de 5,000
- Validación de saldo suficiente
- Validación de claves y números de cuenta

## Requisitos

- Flutter SDK
- Dart SDK
- Android Studio / VS Code con extensiones de Flutter

## Instalación

1. Clonar el repositorio
2. Ejecutar `flutter pub get`
3. Ejecutar `flutter run`

## Uso

1. Crear una cuenta nueva desde la pantalla principal
2. Seleccionar el tipo de retiro deseado
3. Ingresar el número de cuenta y la clave correspondiente
4. Ingresar el monto a retirar
5. Verificar el desglose de billetes

## Tecnologías Utilizadas

- Flutter
- Dart
- Provider para gestión de estado
- SharedPreferences para almacenamiento local
- Material Design 3
- Google Fonts
- Flutter Animate para animaciones
