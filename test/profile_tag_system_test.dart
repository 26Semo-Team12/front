// Feature: profile-tag-system, Property 2: LocationModel 직렬화 라운드트립
import 'package:glados/glados.dart';
import 'package:front/core/models/user_profile.dart';

void main() {
  // **Validates: Requirements 1.2**
  Glados2(any.letters, any.letters).test(
    'LocationModel serialization round trip',
    (province, district) {
      final model = LocationModel(province: province, district: district);
      final roundTripped = LocationModel.fromJson(model.toJson());
      expect(roundTripped, equals(model));
    },
  );
}
