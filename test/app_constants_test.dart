import 'package:flutter_test/flutter_test.dart';
import 'package:ai_chat/features/foundation/constants/app_constants.dart';

void main() {
  group('AppConstants', () {
    test('appVersion is non-empty', () {
      expect(AppConstants.appVersion, isNotEmpty);
    });

    test('buildNumber is non-empty', () {
      expect(AppConstants.buildNumber, isNotEmpty);
    });

    test('aiModel is non-empty', () {
      expect(AppConstants.aiModel, isNotEmpty);
    });

    test('aiProvider is non-empty', () {
      expect(AppConstants.aiProvider, isNotEmpty);
    });

    test('values are correct', () {
      expect(AppConstants.appVersion, equals('1.0.0'));
      expect(AppConstants.buildNumber, equals('1'));
    });
  });
}
