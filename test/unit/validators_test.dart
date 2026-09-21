import 'package:flutter_test/flutter_test.dart';
import 'package:farmayopin/core/utils/validators.dart';

void main() {
  group('Validators Test', () {
    test('validateEmail valida correos válidos e inválidos', () {
      expect(Validators.validateEmail(null), isNotNull);
      expect(Validators.validateEmail(''), isNotNull);
      expect(Validators.validateEmail('correo-invalido'), isNotNull);
      expect(Validators.validateEmail('usuario@dominio'), isNotNull);
      expect(Validators.validateEmail('gaston.perez@estudiantes.utec.edu.uy'), isNull);
    });

    test('validatePassword valida longitud mínima', () {
      expect(Validators.validatePassword(null), isNotNull);
      expect(Validators.validatePassword(''), isNotNull);
      expect(Validators.validatePassword('12345'), isNotNull);
      expect(Validators.validatePassword('123456'), isNull);
    });

    test('validateCardExpiry rechaza tarjetas vencidas y formatos inválidos', () {
      final hoy = DateTime(2026, 9, 19);

      // Vigentes: mes actual (válida hasta fin de mes), futuro
      expect(Validators.validateCardExpiry('09/26', now: hoy), isNull);
      expect(Validators.validateCardExpiry('10/26', now: hoy), isNull);
      expect(Validators.validateCardExpiry('01/27', now: hoy), isNull);
      expect(Validators.validateCardExpiry('12/30', now: hoy), isNull);

      // Vencidas
      expect(Validators.validateCardExpiry('08/26', now: hoy), 'La tarjeta está vencida');
      expect(Validators.validateCardExpiry('12/25', now: hoy), 'La tarjeta está vencida');
      expect(Validators.validateCardExpiry('01/20', now: hoy), 'La tarjeta está vencida');

      // Formato / mes inválido
      expect(Validators.validateCardExpiry(null, now: hoy), isNotNull);
      expect(Validators.validateCardExpiry('', now: hoy), isNotNull);
      expect(Validators.validateCardExpiry('0829', now: hoy), isNotNull);
      expect(Validators.validateCardExpiry('8/29', now: hoy), isNotNull);
      expect(Validators.validateCardExpiry('13/29', now: hoy), 'Mes inválido');
      expect(Validators.validateCardExpiry('00/29', now: hoy), 'Mes inválido');
    });
  });
}
