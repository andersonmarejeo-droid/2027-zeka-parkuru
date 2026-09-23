# Zekâ Parkuru — Gerçek Cihaz Yayın Test Matrisi

## A. Görsel IQ 1–10

Her seviyede en az iki tam oturum:

- [ ] Aynı şık iki kez görünmüyor
- [ ] Görsel olarak aynı iki şık yok
- [ ] Mantıksal olarak aynı iki şık yok (özellikle yalnız renk farkı)
- [ ] Çözüm metni gerçekten gösterilen kuralla eşleşiyor
- [ ] Adet sorularında 1/2/3/4 seçenekleri birbirinden ayırt edilebilir
- [ ] Döndürmede yön ve açı cevapla birebir uyumlu
- [ ] Matrix 2×2 ve 3×3'te satır/sütun kuralı tutarlı
- [ ] Overlay/XOR/simetri nokta deseni çift çizilmiyor
- [ ] Geri/ileri geçişte eski soru state'i taşınmıyor
- [ ] 320 px sınıfı küçük ekranda taşma yok

## B. Firebase temel akış

- [ ] İlk çevrim içi açılışta anonim auth oluşuyor
- [ ] App Check release / Play Integrity başarılı
- [ ] Dünya sıralaması yazma/okuma
- [ ] Arkadaş kodu arama
- [ ] 1'e 1 davet oluşturma/kabul
- [ ] Rakip skor bildirimi
- [ ] Düello sonuç bildirimi

## C. Arena iki cihaz

- [ ] A cihazı grup oluşturur
- [ ] B kod/link ile katılır
- [ ] A yarışma başlatır
- [ ] Her iki cihaz aynı gameIds/layoutCodes alır
- [ ] Oyuncu başına oyun başına tek sonuç oluşur
- [ ] Canlı sıralama iki cihazda aynı
- [ ] Yarışma sonucu bildirimi gelir

## D. Linkler

- [ ] `davet.html?c=...` tarayıcıda açılır
- [ ] Uygulama kuruluysa deep link challenge ekranına gider
- [ ] `arena.html?g=...&code=...` Arena'yı açar
- [ ] App Links tamamlandıktan sonra HTTPS link doğrudan uygulamaya gider

## E. Gizlilik/silme

- [ ] Ayarlar → Gizlilik ve veri açılır
- [ ] Silme isteği onay diyaloğu gösterir
- [ ] İstek Firestore'a yazılır
- [ ] Function isteği işler
- [ ] leaderboard / device token / sosyal kayıtlar temizlenir
- [ ] anonim Firebase kullanıcı silinir
- [ ] yerel oyun ilerlemesi korunur

## F. Release smoke

- [ ] Release AAB derlenir
- [ ] Internal Testing üzerinden kurulur
- [ ] açılış animasyonu
- [ ] 11 oyun açılışı
- [ ] ses/titreşim
- [ ] TR + EN + en az bir ek dil
- [ ] küçük ekran + büyük ekran
- [ ] uygulamayı arka plana alma/geri dönme
- [ ] bildirimden deep link
