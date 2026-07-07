import 'package:flutter_test/flutter_test.dart';
import 'package:herzon/core/constants/app_constants.dart';

void main() {
  test('proximity radius is 2km', () {
    expect(AppConstants.proximityRadiusMeters, 2000.0);
  });
}
