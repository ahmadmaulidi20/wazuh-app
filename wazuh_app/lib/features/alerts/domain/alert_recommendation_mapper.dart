import '../../../core/models/alert_model.dart';
import '../../../core/models/alert_recommendation.dart';

class AlertRecommendationMapper {
  static const Map<int, AlertRecommendation> _byRuleId = {
    5712: AlertRecommendation(
      attackType: 'Brute-Force SSH',
      summary:
          'Terjadi banyak percobaan login SSH dengan user yang tidak ada secara beruntun '
          'dari alamat IP yang sama dalam waktu singkat. Ini merupakan pola serangan '
          'brute-force untuk menebak kombinasi username dan password.',
      actions: [
        'Blokir IP sumber di firewall. Active-response firewall-drop sudah otomatis aktif jika terkonfigurasi.',
        'Pastikan tidak ada akun sistem yang menggunakan password lemah atau umum.',
        'Batasi akses SSH hanya untuk IP tepercaya melalui AllowUsers / AllowGroups.',
        'Nonaktifkan login menggunakan password dan aktifkan autentikasi berbasis kunci (SSH key).',
        'Pertimbangkan fail2ban atau rate-limiting untuk percobaan login SSH.',
      ],
    ),
    5763: AlertRecommendation(
      attackType: 'Brute-Force SSH',
      summary:
          'Terjadi banyak percobaan login SSH yang gagal dari alamat IP yang sama dalam '
          'waktu singkat. Indikasi kuat adanya upaya brute-force terhadap akun pengguna valid.',
      actions: [
        'Blokir IP sumber di firewall. Active-response firewall-drop sudah otomatis aktif jika terkonfigurasi.',
        'Ganti password akun yang menjadi target penyerangan.',
        'Aktifkan two-factor authentication (2FA) jika didukung.',
        'Batasi jumlah percobaan login gagal melalui konfigurasi SSH dan fail2ban.',
        'Pantau log autentikasi untuk aktivitas mencurigakan lanjutan.',
      ],
    ),
    5720: AlertRecommendation(
      attackType: 'Brute-Force SSH',
      summary:
          'Banyak kegagalan autentikasi SSH terdeteksi dalam periode singkat dari IP sumber '
          'yang sama, menandakan percobaan brute-force terhadap kredensial.',
      actions: [
        'Blokir IP sumber di firewall (active-response firewall-drop aktif otomatis).',
        'Perkuat kebijakan password dan aktifkan autentikasi berbasis kunci.',
        'Batasi akses SSH dan gunakan port non-standar jika perlu.',
        'Terapkan rate-limiting pada percobaan login via fail2ban.',
        'Tinjau apakah ada akun layanan yang menggunakan password default.',
      ],
    ),
    5551: AlertRecommendation(
      attackType: 'Brute-Force SSH',
      summary:
          'Beberapa kegagalan login terdeteksi melalui mekanisme PAM dalam waktu singkat, '
          'pola khas serangan brute-force terhadap layanan autentikasi.',
      actions: [
        'Blokir IP sumber di firewall jika serangan terus berlanjut.',
        'Ganti password akun yang diserang dan gunakan password yang kuat.',
        'Batasi akses layanan hanya untuk jaringan/IP yang tepercaya.',
        'Aktifkan penguncian akun (account lockout) setelah beberapa percobaan gagal.',
        'Aktifkan pencatatan login untuk membantu investigasi forensik.',
      ],
    ),
    5710: AlertRecommendation(
      attackType: 'Percobaan Login Gagal',
      summary:
          'Ada percobaan login SSH menggunakan username yang tidak terdaftar di sistem. '
          'Ini bisa menjadi tahap awal pencarian akun valid oleh penyerang.',
      actions: [
        'Pantau IP sumber; kumpulkan beberapa kejadian sebelum memutuskan pemblokiran.',
        'Gunakan password dan username yang tidak mudah ditebak.',
        'Pertimbangkan fail2ban untuk menangani percobaan berulang.',
        'Periksa log autentikasi untuk pola serangan dari IP lain.',
      ],
    ),
    5715: AlertRecommendation(
      attackType: 'Percobaan Login Gagal',
      summary:
          'Ada kegagalan autentikasi SSH karena password salah untuk sebuah akun. '
          'Dapat terjadi karena kesalahan pengguna, tetapi bisa juga bagian dari serangan brute-force.',
      actions: [
        'Verifikasi apakah kegagalan berasal dari pengguna sah yang lupa password.',
        'Jika berulang dari IP yang sama, blokir IP tersebut di firewall.',
        'Terapkan kebijakan kata sandi yang kuat dan cegah penggunaan ulang password.',
      ],
    ),
    5104: AlertRecommendation(
      attackType: 'Percobaan Login Gagal',
      summary:
          'Terjadi kegagalan login ke sistem. Kejadian berulang dapat mengindikasikan '
          'upaya masuk tanpa izin.',
      actions: [
        'Pantau frekuensi kegagalan login dari IP sumber.',
        'Blokir IP yang menunjukkan pola brute-force.',
        'Pastikan akun tidak menggunakan kredensial yang bocor di internet.',
      ],
    ),
    5762: AlertRecommendation(
      attackType: 'Percobaan Login Gagal',
      summary:
          'Koneksi SSH di-reset saat proses autentikasi berlangsung. Umumnya karena '
          'percobaan login gagal atau permintaan koneksi yang tidak biasa.',
      actions: [
        'Periksa pola reset koneksi dari IP yang sama dalam jumlah besar.',
        'Blokir IP mencurigakan di firewall jika frekuensinya tinggi.',
        'Pastikan konfigurasi SSH aman (MaxAuthTries dibatasi).',
      ],
    ),
    100102: AlertRecommendation(
      attackType: 'Pemindaian Port (Nmap)',
      summary:
          'IDS (Suricata) mendeteksi pemindaian port TCP SYN dengan pola Nmap. Pemindaian '
          'port biasanya merupakan langkah awal penyerang untuk memetakan layanan yang terbuka.',
      actions: [
        'Blokir IP pemindai di firewall untuk mencegah eksploitasi lanjutan.',
        'Tutup port yang tidak digunakan dan minimalkan layanan yang terbuka ke publik.',
        'Pastikan hanya layanan yang benar-benar dibutuhkan yang dapat diakses dari luar.',
        'Pantau IP pemindai untuk aktivitas mencurigakan lanjutan.',
        'Perkuat aturan firewall (iptables/ufw) dan hindari port standar untuk layanan penting.',
      ],
    ),
    86601: AlertRecommendation(
      attackType: 'Alarm IDS (Suricata)',
      summary:
          'IDS Suricata menghasilkan alarm keamanan terhadap lalu lintas jaringan. '
          'Perlu ditinjau apakah lalu lintas tersebut benar-benar berbahaya.',
      actions: [
        'Tinjau detail alarm IDS termasuk signature dan IP yang terlibat.',
        'Korelasikan dengan log lain untuk memastikan apakah serangan benar-benar berhasil.',
        'Blokir IP sumber yang terbukti melakukan serangan.',
        'Update ruleset signature Suricata secara berkala.',
      ],
    ),
    5402: AlertRecommendation(
      attackType: 'Eskalasi Privilege (sudo)',
      summary:
          'Eksekusi perintah sudo ke ROOT berhasil dilakukan. Ini aktivitas normal bagi '
          'administrator, tetapi perlu dipastikan memang dilakukan oleh pengguna sah.',
      actions: [
        'Verifikasi bahwa eksekusi sudo dilakukan oleh administrator yang sah.',
        'Tinjau log sudo (secure/auth) secara berkala untuk mendeteksi penyalahgunaan.',
        'Batasi akses sudo hanya untuk pengguna yang membutuhkan.',
        'Gunakan prinsip least privilege untuk akun administratif.',
      ],
    ),
    5501: AlertRecommendation(
      attackType: 'Perubahan Akun Pengguna',
      summary:
          'Akun pengguna baru ditambahkan ke sistem melalui perintah useradd/groupadd. '
          'Perlu dipastikan ini bukan akun backdoor yang dibuat penyerang.',
      actions: [
        'Verifikasi penambahan akun dengan administrator sistem.',
        'Periksa apakah akun baru memiliki hak administratif (sudo).',
        'Hapus akun yang tidak dikenal atau tidak diotorisasi.',
        'Terapkan kebijakan pengelolaan akun dan audit perubahan akun.',
      ],
    ),
    5502: AlertRecommendation(
      attackType: 'Perubahan Akun Pengguna',
      summary:
          'Akun pengguna dihapus atau dimodifikasi dari sistem. Perlu dipastikan perubahan '
          'ini sah dan tidak merusak akses layanan.',
      actions: [
        'Verifikasi penghapusan akun dengan administrator sistem.',
        'Pastikan penghapusan tidak disalahgunakan untuk menghilangkan jejak.',
        'Cadangkan konfigurasi akun penting sebelum perubahan.',
      ],
    ),
    5503: AlertRecommendation(
      attackType: 'Perubahan Akun Pengguna',
      summary:
          'Akun pengguna ditambahkan ke grup sudo/administratif. Ini meningkatkan hak akses '
          'dan berisiko jika tidak disengaja.',
      actions: [
        'Verifikasi penambahan ke grup administratif dengan administrator.',
        'Tinjau daftar anggota grup sudo secara berkala.',
        'Lepaskan keanggotaan yang tidak diperlukan (least privilege).',
      ],
    ),
    510: AlertRecommendation(
      attackType: 'Aktivitas Login Sukses',
      summary:
          'Sesi login berhasil dibuka pada sistem. Aktivitas normal, tetapi perlu dipastikan '
          'login dilakukan oleh pengguna yang sah.',
      actions: [
        'Verifikasi sesi login terhadap daftar pengguna aktif.',
        'Tinjau pola login di luar jam kerja atau dari IP tidak dikenal.',
        'Terapkan pencatatan login dan peringatan untuk lokasi tidak biasa.',
      ],
    ),
    591: AlertRecommendation(
      attackType: 'Aktivitas Login Sukses',
      summary:
          'Koneksi SSH berhasil dilakukan. Pastikan koneksi berasal dari pengguna dan '
          'lokasi yang diharapkan.',
      actions: [
        'Pastikan koneksi berasal dari IP/pengguna yang dikenal.',
        'Pantau sesi SSH aktif dan putuskan sesi yang mencurigakan.',
        'Gunakan autentikasi kunci untuk mengurangi risiko penyusupan kredensial.',
      ],
    ),
    2902: AlertRecommendation(
      attackType: 'Serangan Web',
      summary:
          'Terjadi kegagalan autentikasi pada layanan web. Bisa merupakan percobaan '
          'brute-force login atau penyalahgunaan formulir.',
      actions: [
        'Blokir IP yang melakukan banyak percobaan login gagal.',
        'Aktifkan rate-limiting dan captcha pada halaman login.',
        'Pastikan aplikasi web selalu diperbarui dan bebas kerentanan.',
        'Perkuat autentikasi dengan multi-factor (MFA).',
      ],
    ),
    2904: AlertRecommendation(
      attackType: 'Serangan Web',
      summary:
          'Aktivitas mencurigakan terdeteksi pada layanan web, kemungkinan percobaan '
          'eksploitasi atau serangan terhadap aplikasi.',
      actions: [
        'Tinjau log akses web untuk pola serangan (SQLi, XSS, path traversal).',
        'Blokir IP sumber serangan di firewall/WAF.',
        'Perbarui aplikasi dan framework ke versi terbaru.',
        'Aktifkan web application firewall (ModSecurity) untuk mitigasi.',
      ],
    ),
    504: AlertRecommendation(
      attackType: 'Agent Terputus',
      summary:
          'Agent Wazuh terputus dari manager. Kehilangan visibilitas dapat dimanfaatkan '
          'penyerang untuk menghindari deteksi (evasion).',
      actions: [
        'Segera periksa konektivitas jaringan antara agent dan manager.',
        'Pastikan layanan agent berjalan dan mengirim data.',
        'Verifikasi tidak ada gangguan/takedown yang disengaja oleh penyerang.',
        'Konfigurasi ulang agent jika koneksi tidak pulih otomatis.',
      ],
    ),
  };

  static const Map<String, AlertRecommendation> _byGroupKeyword = {
    'sshd': AlertRecommendation(
      attackType: 'Aktivitas SSH',
      summary:
          'Terjadi aktivitas pada layanan SSH. Perlu ditinjau apakah pola aktivitas '
          'tersebut wajar atau bagian dari serangan.',
      actions: [
        'Tinjau log autentikasi SSH untuk kegagalan berulang.',
        'Blokir IP dengan percobaan login berlebih.',
        'Batasi akses SSH dan aktifkan autentikasi kunci.',
      ],
    ),
    'authentication_failures': AlertRecommendation(
      attackType: 'Kegagalan Autentikasi',
      summary:
          'Terjadi serangkaian kegagalan autentikasi pada sistem. Ini indikasi awal '
          'percobaan akses tanpa izin.',
      actions: [
        'Pantau IP sumber dan frekuensi kegagalan.',
        'Blokir IP dengan pola brute-force di firewall.',
        'Perkuat kebijakan password dan aktifkan MFA.',
      ],
    ),
    'suricata': AlertRecommendation(
      attackType: 'Alarm IDS (Suricata)',
      summary:
          'IDS Suricata mendeteksi lalu lintas mencurigakan di jaringan.',
      actions: [
        'Tinjau signature dan IP yang terlibat.',
        'Korelasikan dengan log lain sebelum bertindak.',
        'Blokir IP penyerang dan perbarui signature ruleset.',
      ],
    ),
    'ids': AlertRecommendation(
      attackType: 'Alarm IDS',
      summary:
          'Sistem deteksi intrusi menghasilkan alarm terhadap aktivitas jaringan.',
      actions: [
        'Analisis alarm untuk membedakan serangan nyata dan false positive.',
        'Blokir IP yang terbukti menyerang.',
        'Tinjau kebijakan deteksi dan update signature.',
      ],
    ),
  };

  static const AlertRecommendation _defaultRecommendation = AlertRecommendation(
    attackType: 'Aktivitas Keamanan',
    summary:
        'Alert keamanan terdeteksi pada sistem. Tinjau detail alert untuk memahami '
        'konteks dan dampak dari aktivitas tersebut.',
    actions: [
      'Periksa detail alert termasuk IP sumber, aturan, dan log lengkap.',
      'Pantau IP sumber untuk aktivitas mencurigakan berulang.',
      'Blokir IP mencurigakan di firewall jika perlu.',
      'Tinjau kebijakan keamanan dan perbarui sistem secara berkala.',
    ],
  );

  static AlertRecommendation recommend(AlertModel alert) {
    if (alert.ruleId != null && _byRuleId.containsKey(alert.ruleId)) {
      return _byRuleId[alert.ruleId]!;
    }

    final groups = alert.ruleGroups?.toLowerCase() ?? '';
    if (groups.isNotEmpty) {
      final matched = _byGroupKeyword.entries
          .where((e) => groups.contains(e.key))
          .map((e) => e.value)
          .toList();
      if (matched.isNotEmpty) return matched.first;
    }

    final description = (alert.ruleDescription ?? '').toLowerCase();
    if (description.contains('suricata') || description.contains('port scan')) {
      return _byRuleId[100102]!;
    }
    if (description.contains('brute') || description.contains('bruteforce')) {
      return _byRuleId[5712]!;
    }

    return _defaultRecommendation;
  }
}
