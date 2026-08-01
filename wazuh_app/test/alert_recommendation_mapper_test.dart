import 'package:flutter_test/flutter_test.dart';
import 'package:wazuh_app/core/models/alert_model.dart';
import 'package:wazuh_app/features/alerts/domain/alert_recommendation_mapper.dart';

AlertModel _alert({
  int? ruleId,
  String? ruleGroups,
  String? ruleDescription,
}) {
  return AlertModel(
    id: 'test-1',
    ruleId: ruleId,
    ruleGroups: ruleGroups,
    ruleDescription: ruleDescription,
  );
}

void main() {
  group('AlertRecommendationMapper.recommend', () {
    test('memetakan rule ID SSH brute-force', () {
      final r = AlertRecommendationMapper.recommend(_alert(ruleId: 5712));
      expect(r.attackType, 'Brute-Force SSH');
      expect(r.actions, isNotEmpty);
    });

    test('memetakan rule 5720 dan 5551 ke Brute-Force SSH', () {
      expect(
        AlertRecommendationMapper.recommend(_alert(ruleId: 5720)).attackType,
        'Brute-Force SSH',
      );
      expect(
        AlertRecommendationMapper.recommend(_alert(ruleId: 5551)).attackType,
        'Brute-Force SSH',
      );
    });

    test('memetakan rule Nmap port scan', () {
      final r = AlertRecommendationMapper.recommend(_alert(ruleId: 100102));
      expect(r.attackType, 'Pemindaian Port (Nmap)');
    });

    test('memetakan rule Suricata alert', () {
      final r = AlertRecommendationMapper.recommend(_alert(ruleId: 86601));
      expect(r.attackType, 'Alarm IDS (Suricata)');
    });

    test('memetakan rule sudo escalation', () {
      final r = AlertRecommendationMapper.recommend(_alert(ruleId: 5402));
      expect(r.attackType, 'Eskalasi Privilege (sudo)');
    });

    test('memetakan rule perubahan akun', () {
      final r = AlertRecommendationMapper.recommend(_alert(ruleId: 5501));
      expect(r.attackType, 'Perubahan Akun Pengguna');
    });

    test('fallback ke group sshd', () {
      final r = AlertRecommendationMapper.recommend(
        _alert(ruleId: 99999, ruleGroups: 'syslog,sshd'),
      );
      expect(r.attackType, 'Aktivitas SSH');
    });

    test('fallback ke group authentication_failures', () {
      final r = AlertRecommendationMapper.recommend(
        _alert(ruleGroups: 'authentication_failures,pci_dss_11.4'),
      );
      expect(r.attackType, 'Kegagalan Autentikasi');
    });

    test('fallback ke group suricata', () {
      final r = AlertRecommendationMapper.recommend(
        _alert(ruleGroups: 'ids,suricata'),
      );
      expect(r.attackType, 'Alarm IDS (Suricata)');
    });

    test('fallback dari deskripsi port scan', () {
      final r = AlertRecommendationMapper.recommend(
        _alert(ruleDescription: 'Suricata detected Nmap port scan'),
      );
      expect(r.attackType, 'Pemindaian Port (Nmap)');
    });

    test('default ketika tidak ada informasi', () {
      final r = AlertRecommendationMapper.recommend(_alert());
      expect(r.attackType, 'Aktivitas Keamanan');
      expect(r.actions, isNotEmpty);
    });
  });
}
