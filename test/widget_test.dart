import 'package:flutter_test/flutter_test.dart';
import 'package:herzon/core/constants/app_constants.dart';

void main() {
  test('proximity radius is 500m', () {
    expect(AppConstants.proximityRadiusMeters, 500.0);
  });
}
