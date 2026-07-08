import 'package:flutter_test/flutter_test.dart';
import 'package:genshin_builder_mobile/data/hoyolab/hoyolab_auth.dart';

void main() {
  group('HoyolabAuth.generateDsToken', () {
    test('format is t,r,md5hex', () {
      final token = HoyolabAuth.generateDsToken(
        queryParameters: {'role_id': '123456789', 'server': 'os_asia'},
      );
      final parts = token.split(',');
      expect(parts, hasLength(3));
      expect(int.tryParse(parts[0]), isNotNull);
      expect(int.tryParse(parts[1]), greaterThanOrEqualTo(100000));
      expect(parts[2], hasLength(32));
    });
  });
}
