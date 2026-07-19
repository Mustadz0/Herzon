import 'package:flutter_test/flutter_test.dart';
import 'package:herzon/data/models/zone_model.dart';

void main() {
  group('ZoneModel', () {
    final json = {
      'id': 'zone-1',
      'zone_key': 'alger-centre',
      'zone_name': 'Alger Centre',
      'center_lat': 36.75,
      'center_lng': 3.06,
      'heat_score': 30,
      'active_users': 42,
      'recent_posts': 15,
      'recent_vibes': 8,
      'recent_checkins': 22,
      'dominant_activity': 'posts',
      'updated_at': '2026-07-12T10:00:00Z',
    };

    test('fromJson parses correctly', () {
      final zone = ZoneModel.fromJson(json);
      expect(zone.id, 'zone-1');
      expect(zone.zoneName, 'Alger Centre');
      expect(zone.centerLat, 36.75);
      expect(zone.centerLng, 3.06);
      expect(zone.heatScore, 30);
      expect(zone.activeUsers, 42);
    });

    test('toJson roundtrip', () {
      final original = ZoneModel.fromJson(json);
      final out = original.toJson();
      final restored = ZoneModel.fromJson(out);
      expect(restored.id, original.id);
      expect(restored.heatScore, original.heatScore);
    });

    test('heat labels', () {
      final calm = ZoneModel.fromJson({...json, 'heat_score': 5});
      expect(calm.isCalm, true);
      expect(calm.heatLabel, 'Calme');
      expect(calm.emoji, '•');

      final active = ZoneModel.fromJson({...json, 'heat_score': 15});
      expect(active.isActive, true);
      expect(active.heatLabel, 'Calme+');

      final hot = ZoneModel.fromJson({...json, 'heat_score': 30});
      expect(hot.isHot, true);
      expect(hot.heatLabel, 'Active');
      expect(hot.emoji, '⚡');

      final fire = ZoneModel.fromJson({...json, 'heat_score': 50});
      expect(fire.isOnFire, true);
      expect(fire.heatLabel, 'Très active');
      expect(fire.emoji, '🔥');
    });
  });
}
