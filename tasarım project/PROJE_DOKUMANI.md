# EduTrade - Eğitimsel Sanal Trading Simülatörü
## Proje Amacı ve Gereksinim Analizi

---

## 1. PROJE ÖZETİ

### Proje Adı ve Amacı
**EduTrade**, kullanıcıların kripto para birimleri trading kavramlarını öğrenmelerini ve demo para ile pratik yapmalarını sağlayan bir iOS mobil uygulamasıdır. Uygulama, gerçek para riski olmadan trading deneyimi kazandırırken, kapsamlı eğitim içerikleri ve quiz sistemi ile trading bilgilerini geliştirmelerine yardımcı olur.

### Hedef Kitle
- Trading'e yeni başlayanlar
- Risk almadan trading pratiği yapmak isteyenler
- Trading stratejilerini ve teknikleri öğrenmek isteyenler

### Proje Kapsamı
- Demo para ile sanal trading simülasyonu (100,000 USDT başlangıç bakiyesi)
- 5 eğitim dersi (Trading Basics, Stop Loss, Risk Management, Support/Resistance, Trend Following)
- Her ders için 3-5 soruluk quiz sistemi
- Kullanıcı profil yönetimi ve 6 farklı başarım sistemi
- Trade geçmişi ve portfolio takibi

---

## 2. GEREKSİNİM ANALİZİ

### 2.1 Fonksiyonel Gereksinimler

**Trading Modülü:**
- Kullanıcı 100,000 USDT demo bakiyesi ile başlar
- Mock coin'leri (BTC, ETH, ADA, BNB, SOL, MATIC, LINK, LTC) görüntüleyebilir
- Coin satın alma (Buy) ve satma (Sell) işlemleri yapabilir
- Sistem yeterli bakiye ve coin miktarı kontrolü yapar
- Tüm trade geçmişi ve portfolio görüntülenebilir
- Her trade işlemi kaydedilir (timestamp, miktar, fiyat)

**Eğitim ve Quiz Modülü:**
- 5 ders içeriği görüntülenebilir ve okunabilir
- Her ders için quiz mevcuttur (3-5 çoktan seçmeli soru)
- Quiz skorları hesaplanır ve kaydedilir
- Ders tamamlama ilerlemesi takip edilir

**Profil ve Başarım Sistemi:**
- Kullanıcı bakiyesi, trade sayısı, quiz skorları görüntülenebilir
- Portfolio'daki coin'ler ve değerleri gösterilir
- 6 başarım otomatik olarak takip edilir:
  - First Trade, Progressive Trader (10 trade), Centurion (100 trade)
  - Scholar (tüm dersler), Master Quizzer (%100 quiz), Diversifier (5 coin)
- Tüm ilerleme resetlenebilir

### 2.2 Fonksiyonel Olmayan Gereksinimler

- **Performans**: Uygulama açılışı <2 saniye, UI gecikmesi olmadan çalışır
- **Kullanılabilirlik**: Modern, temiz UI (yuvarlatılmış kartlar, yumuşak renkler), sezgisel navigasyon
- **Güvenilirlik**: Veriler UserDefaults ile cihazda güvenli saklanır, uygulama kapanıp açıldığında korunur
- **Bakım**: MVVM mimarisi, modüler yapı, JSON mock veriler

---

## 3. TEKNİK ÖZELLİKLER

### Platform ve Teknolojiler
- **Platform**: iOS (iPhone & iPad)
- **Programlama Dili**: Swift 5.0+
- **UI Framework**: SwiftUI
- **Minimum iOS**: 18.5+
- **Mimari**: MVVM (Model-View-ViewModel)
- **Veri Depolama**: UserDefaults (local persistence)
- **Veri Formatı**: JSON (mock data: coins.json, learnData.json, quizData.json, achievements.json)

### Veri Modelleri
- **Coin**: id, symbol, name, price, change24h
- **Trade**: id, coinSymbol, coinName, type (buy/sell), amount, price, timestamp
- **Lesson**: id, title, content, duration, category, icon
- **Quiz**: id, lessonId, questions (id, question, options, correctAnswer)
- **User**: balance (100,000), totalQuizScore, numberOfTrades, portfolio, unlockedAchievements

### Sistem Mimarisi
```
Views (SwiftUI) → ViewModels (MVVM) → Models → Persistence (UserDefaults)
  ├─ HomeView          ├─ TradingViewModel      ├─ Coin
  ├─ TradeView         ├─ LearningViewModel     ├─ Trade
  ├─ LearnView         └─ DataManager          ├─ Lesson
  ├─ QuizView                                  ├─ Quiz
  └─ ProfileView                                ├─ User
                                                 └─ Achievement
```

---

## 4. EKRAN TASARIMI VE ÖZELLİKLER

### Ana Navigasyon
Uygulama **TabView** ile 4 ana sekme:
1. **Home** - Dashboard (bakiye, istatistikler, portfolio önizleme)
2. **Trade** - Trading ekranı (coin listesi, buy/sell, trade history)
3. **Learn** - Eğitim (ders listesi, detay, quiz)
4. **Profile** - Profil (istatistikler, başarımlar, portfolio, reset)

### Temel Özellikler
- **HomeView**: Bakiye kartı, "Start Trading" / "Learn Trading" butonları, istatistik grid (trades, quiz score, lessons, achievements), portfolio önizleme
- **TradeView**: Bakiye gösterimi, coin listesi (icon, fiyat, değişim), trade sheet (buy/sell toggle, miktar girişi, hızlı butonlar %25/50/75/Max), trade history
- **LearnView**: İlerleme kartı, ders kartları (başlık, kategori, süre, tamamlanma durumu, quiz skoru), ders detay sayfası, quiz view (ilerleme barı, çoktan seçmeli sorular, sonuç ekranı)
- **ProfileView**: Profil header, istatistikler (trade sayısı, quiz sayısı, ders sayısı, ortalama skor), başarımlar, portfolio detayı, reset butonu

---

## 5. VERİ AKIŞI

### Trading İşlem Akışı
Coin Seç → Trade Sheet → Buy/Sell Seçimi → Miktar Girişi → Validasyon → Trade İşlemi (bakiye/portfolio güncelleme, kayıt) → Başarım Kontrolü

### Eğitim ve Quiz Akışı
Ders Seç → Ders Detay → İçerik Okuma → "Take Quiz" → Quiz (Sorular → Cevaplar → Sonuçlar) → Skor Hesaplama/Kaydetme → Ders Tamamlama → Başarım Kontrolü

---

## 6. BAŞARIM SİSTEMİ

| Başarım | Koşul | Açıklama |
|---------|-------|----------|
| First Trade | 1 trade | İlk trade yapıldı |
| Progressive Trader | 10 trade | 10 trade tamamlandı |
| Centurion | 100 trade | 100 trade tamamlandı |
| Scholar | 5 ders | Tüm dersler tamamlandı |
| Master Quizzer | %100 tüm quiz'ler | Tüm quiz'lerde mükemmel skor |
| Diversifier | 5 farklı coin | Portfolio'da 5 farklı coin |

---

## 7. SONUÇ

EduTrade, MVVM mimarisi ile geliştirilmiş, SwiftUI kullanılarak modern bir kullanıcı arayüzüne sahip, UserDefaults ile veri persistence sağlayan kapsamlı bir iOS uygulamasıdır. Uygulama, eğitim içerikleri, interaktif quiz'ler, sanal trading simülasyonu ve başarım sistemi ile kullanıcılara zengin bir öğrenme deneyimi sunmaktadır.

**Sınırlamalar**: Demo para, mock fiyatlar (gerçek zamanlı değil), offline çalışma, local storage.

**Gelecek Geliştirmeler**: Gerçek zamanlı fiyatlar, grafikler, daha fazla coin ve ders içeriği, sosyal özellikler.

---

**Doküman Versiyonu**: 1.0  
**Tarih**: 2025  
**Proje**: EduTrade - Educational Virtual Trading Simulator
