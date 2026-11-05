import 'package:flutter_test/flutter_test.dart';
import 'package:veyors/core/utils/validators.dart';

void main() {
  group('Validators', () {
    test('validates email addresses', () {
      expect(Validators.email('demo@veyora.app'), isNull);
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email(''), isNotNull);
    });

    test('requires strong passwords', () {
      expect(Validators.password('Demo1234'), isNull);
      expect(Validators.password('short'), isNotNull);
      expect(Validators.password('onlyletters'), isNotNull);
    });

    test('checks confirmation and minimum length', () {
      expect(Validators.confirmPassword('Demo1234', 'Demo1234'), isNull);
      expect(Validators.confirmPassword('Demo1235', 'Demo1234'), isNotNull);
      expect(Validators.minLength('hello', 8, label: 'Bio'), isNotNull);
    });
  });
}
