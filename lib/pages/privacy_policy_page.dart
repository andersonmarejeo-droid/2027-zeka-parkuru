import 'package:flutter/material.dart';

import '../theme/app_visual_theme.dart';

import '../l10n/app_localizations.dart';
import '../services/account_data_service.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  bool _deleting = false;

  Future<void> _requestDeletion() async {
    final bool tr = !context.l10n.isEnglish;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(tr ? 'Çevrim içi verileri sil' : 'Delete online data'),
        content: Text(
          tr
              ? 'Bu işlem anonim çevrim içi profilini, liderlik kaydını, bildirim belirtecini ve sana bağlı sosyal/Arena kayıtlarını silme isteği oluşturur. Yerel oyun ilerlemen cihazda kalır. İşlem geri alınamaz.'
              : 'This creates a request to delete your anonymous online profile, leaderboard record, notification token and social/Arena records associated with you. Local game progress stays on this device. This action cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(tr ? 'VAZGEÇ' : 'CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(tr ? 'SİLME İSTEĞİ GÖNDER' : 'REQUEST DELETION'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    final bool ok = await AccountDataService.instance
        .requestOnlineDataDeletion();
    if (!mounted) return;
    setState(() => _deleting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (tr
                    ? 'Silme isteği gönderildi. Çevrim içi anonim profil yeniden oluşturulana kadar kapatıldı.'
                    : 'Deletion request sent. The anonymous online profile has been signed out.')
              : (tr
                    ? 'Silme isteği gönderilemedi. İnternet/Firebase bağlantısını kontrol edip tekrar deneyin.'
                    : 'Deletion request could not be sent. Check the internet/Firebase connection and try again.'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool tr = !context.l10n.isEnglish;
    final List<_PolicySection> sections = <_PolicySection>[
      _PolicySection(
        tr ? 'Kısa özet' : 'Summary',
        tr
            ? 'Normal oyun ilerlemesi ve tercihler cihazda saklanır. Çevrim içi özellikler kullanıldığında anonim Firebase kullanıcı kimliği, oyuncu adı/avatarı, skor ve yarışma bilgileri, bildirim belirteci ve teknik tanılama/analiz verileri işlenebilir. Uygulama telefon numarası veya e-posta istemez.'
            : 'Normal game progress and preferences are stored on the device. When online features are used, an anonymous Firebase user ID, player name/avatar, scores and competition data, notification token, and technical diagnostics/analytics data may be processed. The app does not ask for a phone number or email address.',
      ),
      _PolicySection(
        tr ? 'İşlenen veriler' : 'Data processed',
        tr
            ? '• Cihazdaki oyun ilerlemesi, yıldızlar ve ayarlar\n• Çevrim içi liderlik ve Arena için anonim kimlik, oyuncu adı/avatarı ve skor bilgileri\n• Firebase Cloud Messaging cihaz belirteci\n• Firebase Analytics kullanım olayları\n• Üretimde Firebase Crashlytics teknik hata kayıtları\n• Firebase App Check / Play Integrity doğrulama bilgileri'
            : '• On-device game progress, stars and settings\n• Anonymous ID, player name/avatar and score data for online leaderboard and Arena\n• Firebase Cloud Messaging device token\n• Firebase Analytics usage events\n• Firebase Crashlytics technical error reports in release builds\n• Firebase App Check / Play Integrity verification information',
      ),
      _PolicySection(
        tr ? 'Kullanım amacı' : 'Why this data is used',
        tr
            ? 'Veriler oyunun çalışması, ilerlemenin gösterilmesi, çevrim içi sıralamalar, davetler, Arena yarışmaları, bildirimler, kötüye kullanımın azaltılması ve uygulama kararlılığının geliştirilmesi için kullanılır.'
            : 'Data is used to operate the game, show progress, provide online rankings, invitations, Arena competitions and notifications, reduce abuse, and improve app stability.',
      ),
      _PolicySection(
        tr
            ? 'Diğer oyuncuların görebildiği bilgiler'
            : 'Information visible to other players',
        tr
            ? 'Çevrim içi özellikler kullanıldığında oyuncu adı/avatarı ile bazı skor, yıldız ve sıralama bilgileri diğer oyuncular tarafından görülebilir. Oyuncu adında gerçek ad veya hassas bilgi kullanılmaması önerilir.'
            : 'When online features are used, other players may see the player name/avatar and some score, star and ranking information. Avoid using a real name or sensitive information as the player name.',
      ),
      _PolicySection(
        tr ? 'Üçüncü taraf altyapısı' : 'Third-party infrastructure',
        tr
            ? 'Uygulama Firebase Authentication, Cloud Firestore, Analytics, Crashlytics, Cloud Messaging ve App Check hizmetlerini kullanır. Bu hizmetlerin işlediği teknik veriler Google/Firebase koşullarına tabidir.'
            : 'The app uses Firebase Authentication, Cloud Firestore, Analytics, Crashlytics, Cloud Messaging and App Check. Technical data processed by these services is subject to Google/Firebase terms.',
      ),
      _PolicySection(
        tr ? 'İletişim ve veri talepleri' : 'Contact and data requests',
        tr
            ? 'Bu ekranın altındaki düğmeyle anonim çevrim içi profil ve ona bağlı veriler için silme isteği gönderebilirsin. Ek gizlilik veya veri talepleri yayınlanan Play Store geliştirici iletişim adresinden iletilebilir.'
            : 'Use the button at the bottom of this screen to request deletion of the anonymous online profile and associated data. Additional privacy or data requests may be sent through the developer contact address published on Google Play.',
      ),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          tr ? 'Gizlilik Politikası' : 'Privacy Policy',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: ZpVisualPalette.of(context).surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'ZEKA PARKURU',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tr
                        ? 'Uygulama içi gizlilik özeti • 25 Ağustos 2026'
                        : 'In-app privacy summary • 25 August 2026',
                    style: const TextStyle(color: Colors.white60),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ...sections.expand(
              (_PolicySection section) => <Widget>[
                _PolicyCard(section: section),
                const SizedBox(height: 12),
              ],
            ),
            const SizedBox(height: 4),
            FilledButton.tonalIcon(
              key: const ValueKey<String>('online_data_delete_button'),
              onPressed: _deleting ? null : _requestDeletion,
              icon: _deleting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_forever_outlined),
              label: Text(
                tr ? 'ÇEVRİM İÇİ VERİLERİMİ SİL' : 'DELETE MY ONLINE DATA',
              ),
            ),
            const SizedBox(height: 14),
            Text(
              tr
                  ? 'Not: Play Store yayını öncesi destek e-postası ve web gizlilik politikası URL’si son kez doğrulanmalıdır.'
                  : 'Note: Before Google Play release, verify the support email and the hosted privacy-policy URL one final time.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicySection {
  const _PolicySection(this.title, this.body);

  final String title;
  final String body;
}

class _PolicyCard extends StatelessWidget {
  const _PolicyCard({required this.section});

  final _PolicySection section;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: ZpVisualPalette.of(context).surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            section.title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            section.body,
            style: const TextStyle(color: Colors.white70, height: 1.5),
          ),
        ],
      ),
    );
  }
}
