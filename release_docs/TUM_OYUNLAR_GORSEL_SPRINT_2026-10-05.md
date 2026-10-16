# Oyun görsel ve okunurluk sprinti — 5 Ekim 2026

Hedef: ana menünün sakin Zihin Bahçesi görünümünü 46 aktif oyunun katalog kartı, bölüm seçimi, oyun alanı ve sonuçlarına taşımak. Flutter içinde çözünürlükten bağımsız çizimler; kağıt, ahşap, seramik, gerçekçi masa/keçe ve harita yüzeyleri kullanılacak. Neon parıltısı, gereksiz süs ve küçük belirsiz ikonların yerine oynanışı anlatan görseller konulacak.

Kabul: oyun adı iki satırda okunur; açıklama ve ikincil metin koyu ve belirgindir; butonlar en az 48 dp; oyun alanında renk dışında şekil/sınır/işaret ayrımı vardır. Kart görselleri katalogda 96–112 dp, bölüm listesinde 92–110 dp genişliğindedir. Dar ekran ve büyük yazıda taşma kontrol edilir. Kayıt anahtarları, bulmaca üretimi, zorluk, puanlama ve aktif katalog korunur.

Sıra: ortak tasarım altyapısı → aşağıdaki oyunları sırayla düzenleme → bütün aktif giriş ve ilk oyun ekranlarını test etme → oyun görsellerinin ekran çıktısını inceleme → Android release derleme.

| Sıra | Oyun | Oyun içi tasarım işi |
|---|---|---|
| 1 | Mayın Dedektifi | Seramik hücre, bayrak ve sayı kontrastı |
| 2 | Dedektif Notları | Kağıt dosya, net ipuçları ve işaretleme |
| 3 | Ağırlık Dengesi | Ahşap/metal terazi, okunaklı ağırlıklar |
| 4 | Sayı Ustası | Açık kağıt, doğal sayı ve işlem renkleri |
| 5 | 15 Taş Ustası | Ahşap taş, koyu oyma sayılar ve boşluk |
| 6 | Hedef 24 | Doğal sayı taşları, açık işlem alanı |
| 7 | Mini Sudoku | Kağıt ızgara, belirgin seçili hücre/not |
| 8 | KenKen Küpü | Net kafes sınırı ve işlem etiketi |
| 9 | Gizli Kütleler | Anlaşılır kütle ve terazi sunumu |
| 10 | Kakuro | Koyu ipucu alanı ve okunur beyaz hücre |
| 11 | Blok Atölyesi | Doğal seramik parçalar, açık ızgara |
| 12 | Görsel IQ | Büyük şekil ve net seçenekler |
| 13 | Şekil Birleştir | Ahşap/doğal parça ve yerleşim vurgusu |
| 14 | Hafıza Labirenti | Sakin açık hücreler, belirgin hedef/rota |
| 15 | Kart Çifti | Büyük kart yüzleri ve aynı deste arka yüzü |
| 16 | Odak Filtresi | Belirgin sinyal ve tek büyük seçim eylemi |
| 17 | Değişeni Bul | Büyük karşılaştırma sahneleri |
| 18 | Ritim Hafızası | Doğal vurmalı yüzey ve net aktif pad |
| 19 | Dikkat Tüneli | Büyük kart, net hedef ve kontrollü dönüş |
| 20 | Hanoi Kulesi | Ahşap disk ve sütunlar, açık masa |
| 21 | Park Yeri | Asfalt/otomobil kimliği, net hedef çıkışı |
| 22 | Satranç Matı | Beyaz taş konturu, doğal tahta kontrastı |
| 23 | Kelime Avı | Koyu harfler, okunur ipucu/seçim |
| 24 | Anlam Eşleştir | Açık kelime kartları ve net eşleşme |
| 25 | Atasözü Tamamla | Kağıt metin, okunaklı seçenekler |
| 26 | Kelime Çarkı | Doğal harf taşları, belirgin bağlantı |
| 27 | Cümle Kur | Net kelime taşları ve sıralama |
| 28 | Yakın Anlam | Kağıt kart, koyu anlam/seçenek |
| 29 | Harf Labirenti | Belirgin harf hücreleri ve rota |
| 30 | Dil Dedektifi | Dosya/kağıt ve okunur ipuçları |
| 31 | Hikâye Sırası | Net hikâye kartları ve sıra |
| 32 | Refleks Avı | Açık alan, hedef/yanlış hedef ayrımı |
| 33 | Şeker Konveyörü | Doğal şeker renkleri, net bant/kaplar |
| 34 | Reversi Arenası | Keçe tahta, belirgin siyah/beyaz taş |
| 35 | Picross Ustası | Net ipucu/ızgara, dolu/boş ayrımı |
| 36 | Ok Rotası | Koyu rotalar ve belirgin çıkış |
| 37 | Döngü Ustası | Kağıt üstünde net çizgi/düğüm |
| 38 | Ada ve Deniz | Deniz/ada doğal renk ve sayı ayrımı |
| 39 | Futoshiki | Koyu sayılar ve okunaklı eşitsizlik |
| 40 | Gökdelenler | Net yükseklik ve kenar ipuçları |
| 41 | Hitori | Dolu/boş hücre, koyu sayılar |
| 42 | Şehir Atlası | Doğal harita, net ipucu ve cevap |
| 43 | Dünya Atlası | Doğal harita, net ipucu ve cevap |
| 44 | Katamino Atölyesi | Ahşap parça ve belirgin yerleşim |
| 45 | Tek Çizgi Ustası | Net çizgi/düğüm ve etkin rota |
| 46 | Ok Labirenti | Açık seramik, net ok/hedef |

## Uygulanan sonuç

46 aktif oyunun tamamı ortak Zihin Bahçesi oyun temasına geçirildi. Katalog ve bölüm kartları büyütüldü; oyun kimliğini anlatan çözünürlükten bağımsız çizimler eklendi. Harita kartları gerçek uygulama harita verisini, satranç kartı oyun içindeki net taş çizimlerini kullanır. Kart Çifti ve Dikkat Tüneli için ev, araba, tekne ve diğer tanınabilir nesne çizimleri hazırlandı.

Açık yüzeylerde metinler koyulaştırıldı; kelime ve sayı alanları, açıklamalar, ipuçları, sonuç düğmeleri ve küçük kenar işaretleri gözden geçirildi. Ahşap, kağıt, keçe ve seramik yüzeyler doğal tonlara çekildi. Dar ekranda alt eylemler gerektiğinde alt alta açılır. Odak Filtresi'nin SEÇ düğmesi ekranın altında sabitlendi; harita ekranındaki sınırsız boyut hatası ve büyük yazıda taşan sonuç/eylem satırları düzeltildi.

Kaldırılmış oyunlar yeniden etkinleştirilmedi. Bu sprintte oyun kayıt anahtarları, puanlama, bulmaca üretimi ve mevcut kullanıcı ilerlemesi değiştirilmedi. Uygulama Flutter olarak kaldı; Unity/Unreal motoruna taşınmadı.

## Doğrulama

- Seçilmiş 97 test dosyasında toplam **498 test geçti**. Bu, tüm depo testlerinin tamamının çalıştırıldığı anlamına gelmez.
- 46 oyunun giriş ve ilk oynanabilir ekranı 320 × 700 boyutta, %130 yazı ölçeğinde sınandı.
- 41 uygun oyunun 10. bölüm ekranı 360 × 780 boyutta, %115 yazı ölçeğinde kontrol edildi.
- 46 oyunun katalog görseli ve ilk oyun ekranı kaydedilip görsel olarak incelendi. Çıktılar: `build/visual_sprint/artwork_catalog.png` ve `boards_1.png`–`boards_6.png`.
- Seçili oyunların cevap verme, bölüm bitirme, sonuç gösterme ve küçük ekran eylemleri için mevcut oynanış testleri de çalıştırıldı.
- Statik analizde yeni hata bulunmadı. Depodaki 5 mevcut uyarı/bilgi (emekli Baloncuk Arenası ve kullanılmayan ana menü yardımcı sınıfı) kaldı.

Kontrol sınırı: gerçek telefonda tüm bölümler tek tek oynanmadı. USB kurulumu ve mağaza yayını bu sprintte yapılmadı.

## Android kurulum paketi

- Release derlemesi başarılı: **1.8.6+22**, 5 Ekim 2026 15:20 (İstanbul).
- Dosya: `build/app/outputs/flutter-apk/app-release.apk` — **105.129.046 bayt**, yaklaşık 100,3 MiB.
- Android APK imza doğrulaması başarılı: v2 imza, tek imzalayan.
- SHA-256: `7C02A55BF5AA6F42884B4A356A96151A0E96997AA58704ACA117F68979FAB81C`.
- Derleme, mevcut kullanıcı Java 21 kurulumu ile yapıldı; sistemin genel Java ayarları ve uygulama bağımlılık sürümleri değiştirilmedi.
- Kart çizimleri uygulama içinde üretildi; büyük fotoğraf paketleri eklenmedi. Önceki release APK'ya göre toplam paket farkı 147.272 bayt oldu.

Ada ve Deniz küçük ekran testindeki geri alma kontrolü de kaydırma ve durum mesajı doğrulamasıyla güçlendirildi; ilgili 3 test tekrar geçti.
