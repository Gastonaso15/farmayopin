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
  });
}
