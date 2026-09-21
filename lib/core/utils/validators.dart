class Validators {
  Validators._();

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor ingresa tu correo electrónico';
    }
    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
    );
    if (!emailRegExp.hasMatch(value.trim())) {
      return 'Ingresa un correo electrónico válido';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu contraseña';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor ingresa tu $fieldName';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Por favor confirma tu contraseña';
    }
    if (value != password) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  static String? validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor ingresa el precio';
    }
    final number = double.tryParse(value.trim().replaceAll(',', '.'));
    if (number == null || number <= 0) {
      return 'El precio debe ser mayor a 0';
    }
    return null;
  }

  static String? validateStock(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor ingresa el stock';
    }
    final number = int.tryParse(value.trim());
    if (number == null || number < 0) {
      return 'El stock no puede ser negativo';
    }
    return null;
  }

  /// Valida la fecha de vencimiento de una tarjeta en formato MM/AA.
  ///
  /// Rechaza formatos inválidos, meses fuera de 1-12 y tarjetas vencidas.
  /// Una tarjeta es válida hasta el último día de su mes de vencimiento.
  /// [now] permite fijar la fecha actual (útil para pruebas).
  static String? validateCardExpiry(String? value, {DateTime? now}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Ingresa el vencimiento (MM/AA)';
    }
    final match = RegExp(r'^(\d{2})/(\d{2})$').firstMatch(text);
    if (match == null) {
      return 'Formato inválido (MM/AA)';
    }
    final month = int.parse(match.group(1)!);
    final year = 2000 + int.parse(match.group(2)!);
    if (month < 1 || month > 12) {
      return 'Mes inválido';
    }
    final today = now ?? DateTime.now();
    final expired = year < today.year || (year == today.year && month < today.month);
    if (expired) {
      return 'La tarjeta está vencida';
    }
    return null;
  }
}
