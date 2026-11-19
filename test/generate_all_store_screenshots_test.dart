import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Generate all 64 store screenshots for 8 languages via Canvas', () async {
    final languages = ['tr', 'en', 'ar', 'id', 'pt', 'es', 'fr', 'de'];

    for (final lang in languages) {
      final isRtl = lang == 'ar';

      for (int screenIdx = 1; screenIdx <= 8; screenIdx++) {
        final data = _getScreenData(lang, screenIdx);

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 1080, 2400));

        _paintStoreScreenshot(canvas, data, screenIdx, isRtl);

        final picture = recorder.endRecording();
        final image = await picture.toImage(1080, 2400);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        picture.dispose();

        final fileName = _getFileName(screenIdx);
        final outPath = 'store_assets/$lang/screenshots/$fileName';
        final file = File(outPath);
        file.parent.createSync(recursive: true);
        file.writeAsBytesSync(byteData!.buffer.asUint8List());
        print('Saved: $outPath (${file.lengthSync()} bytes)');
      }
    }

    print('SUCCESS: All 64 screenshots generated and saved cleanly!');
  });
}

String _getFileName(int idx) {
  return switch (idx) {
    1 => 'screen_01_all_games.png',
    2 => 'screen_02_offline_noads.png',
    3 => 'screen_03_daily_course.png',
    4 => 'screen_04_memory.png',
    5 => 'screen_05_logic_strategy.png',
    6 => 'screen_06_math_puzzle.png',
    7 => 'screen_07_attention_speed.png',
    8 => 'screen_08_stats_iq.png',
    _ => 'screen_$idx.png',
  };
}

class ScreenData {
  final String badge;
  final String title;
  final String subtitle;
  final Color accentColor;
  final Color secondaryColor;
  final String phoneHeaderTitle;
  final String phoneSubHeader;

  const ScreenData({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.secondaryColor,
    required this.phoneHeaderTitle,
    required this.phoneSubHeader,
  });
}

void _paintStoreScreenshot(Canvas canvas, ScreenData data, int screenIdx, bool isRtl) {
  // 1. Dark Gradient Background
  final bgPaint = Paint()
    ..shader = ui.Gradient.linear(
      const Offset(540, 0),
      const Offset(540, 2400),
      [
        const Color(0xFF090D16),
        const Color(0xFF0F172A),
      ],
    );
  canvas.drawRect(const Rect.fromLTWH(0, 0, 1080, 2400), bgPaint);

  // 2. Ambient Glow Orbs
  final glowPaint1 = Paint()
    ..color = data.accentColor.withValues(alpha: 0.16)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 120);
  canvas.drawCircle(Offset(isRtl ? 900 : 180, 250), 280, glowPaint1);

  final glowPaint2 = Paint()
    ..color = data.secondaryColor.withValues(alpha: 0.12)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 140);
  canvas.drawCircle(Offset(isRtl ? 150 : 930, 800), 320, glowPaint2);

  // 3. Header Texts
  final textAlign = isRtl ? TextAlign.right : TextAlign.left;
  final textDir = isRtl ? TextDirection.rtl : TextDirection.ltr;

  // 3a. Pill Badge
  final badgeTp = TextPainter(
    text: TextSpan(
      text: data.badge,
      style: TextStyle(
        color: data.accentColor,
        fontSize: 26,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    ),
    textDirection: textDir,
  )..layout();

  final badgeWidth = badgeTp.width + 48;
  final badgeHeight = badgeTp.height + 24;
  final badgeLeft = isRtl ? (1080 - 64 - badgeWidth) : 64.0;
  final badgeTop = 110.0;

  final badgeRRect = RRect.fromRectAndRadius(
    Rect.fromLTWH(badgeLeft, badgeTop, badgeWidth, badgeHeight),
    const Radius.circular(24),
  );

  final badgeBgPaint = Paint()..color = data.accentColor.withValues(alpha: 0.2);
  canvas.drawRRect(badgeRRect, badgeBgPaint);

  final badgeBorderPaint = Paint()
    ..color = data.accentColor.withValues(alpha: 0.6)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;
  canvas.drawRRect(badgeRRect, badgeBorderPaint);

  badgeTp.paint(canvas, Offset(badgeLeft + 24, badgeTop + 12));

  // 3b. Big Display Title
  final titleTp = TextPainter(
    text: TextSpan(
      text: data.title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 54,
        fontWeight: FontWeight.w900,
        height: 1.15,
        letterSpacing: -0.5,
      ),
    ),
    textAlign: textAlign,
    textDirection: textDir,
  )..layout(maxWidth: 952);

  final titleTop = badgeTop + badgeHeight + 24;
  final titleLeft = isRtl ? (1080 - 64 - titleTp.width) : 64.0;
  titleTp.paint(canvas, Offset(titleLeft, titleTop));

  // 3c. Subtitle
  final subTp = TextPainter(
    text: TextSpan(
      text: data.subtitle,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.8),
        fontSize: 28,
        fontWeight: FontWeight.w500,
        height: 1.3,
      ),
    ),
    textAlign: textAlign,
    textDirection: textDir,
  )..layout(maxWidth: 952);

  final subTop = titleTop + titleTp.height + 16;
  final subLeft = isRtl ? (1080 - 64 - subTp.width) : 64.0;
  subTp.paint(canvas, Offset(subLeft, subTop));

  // 4. Smartphone Mockup Frame
  const phoneLeft = 90.0;
  const phoneTop = 640.0;
  const phoneWidth = 900.0;
  const phoneHeight = 1760.0;

  // Shadow
  final phoneRRect = RRect.fromRectAndRadius(
    const Rect.fromLTWH(phoneLeft, phoneTop, phoneWidth, phoneHeight),
    const Radius.circular(54),
  );
  canvas.drawShadow(
    Path()..addRRect(phoneRRect),
    Colors.black.withValues(alpha: 0.8),
    30.0,
    true,
  );

  // Phone Border
  final phoneBorderPaint = Paint()
    ..color = const Color(0xFF334155)
    ..style = PaintingStyle.fill;
  canvas.drawRRect(phoneRRect, phoneBorderPaint);

  // Phone Inner Screen
  const screenLeft = phoneLeft + 8;
  const screenTop = phoneTop + 8;
  const screenWidth = phoneWidth - 16;
  const screenHeight = phoneHeight - 16;

  final screenRRect = RRect.fromRectAndRadius(
    const Rect.fromLTWH(screenLeft, screenTop, screenWidth, screenHeight),
    const Radius.circular(46),
  );
  canvas.drawRRect(screenRRect, Paint()..color = const Color(0xFF0F172A));

  // Dynamic Island
  final islandRRect = RRect.fromRectAndRadius(
    const Rect.fromLTWH(470, screenTop + 14, 140, 24),
    const Radius.circular(12),
  );
  canvas.drawRRect(islandRRect, Paint()..color = Colors.black);

  // Phone Top App Bar
  final barTop = screenTop + 54;
  final barLeft = screenLeft + 32;

  // Avatar Icon circle
  final avatarPaint = Paint()..color = data.accentColor;
  canvas.drawCircle(Offset(barLeft + 26, barTop + 26), 26, avatarPaint);

  // App Bar Titles
  final barTitleTp = TextPainter(
    text: TextSpan(
      text: data.phoneHeaderTitle,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    ),
    textDirection: textDir,
  )..layout(maxWidth: 500);

  final barSubTp = TextPainter(
    text: TextSpan(
      text: data.phoneSubHeader,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.6),
        fontSize: 18,
      ),
    ),
    textDirection: textDir,
  )..layout(maxWidth: 500);

  barTitleTp.paint(canvas, Offset(barLeft + 68, barTop + 4));
  barSubTp.paint(canvas, Offset(barLeft + 68, barTop + 30));

  // Score Pill on right
  final scoreRRect = RRect.fromRectAndRadius(
    Rect.fromLTWH(screenWidth + screenLeft - 150, barTop + 8, 120, 38),
    const Radius.circular(20),
  );
  canvas.drawRRect(scoreRRect, Paint()..color = const Color(0xFF1E293B));
  canvas.drawRRect(
    scoreRRect,
    Paint()
      ..color = const Color(0xFF475569)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5,
  );

  final scoreTp = TextPainter(
    text: const TextSpan(
      text: '★ 1480',
      style: TextStyle(
        color: Color(0xFFFBBF24),
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  scoreTp.paint(canvas, Offset(screenWidth + screenLeft - 134, barTop + 16));

  // Divider
  canvas.drawLine(
    Offset(screenLeft, barTop + 64),
    Offset(screenLeft + screenWidth, barTop + 64),
    Paint()..color = const Color(0xFF1E293B)..strokeWidth = 2,
  );

  // 5. In-Screen Gameplay Content
  final contentTop = barTop + 80;
  final contentLeft = screenLeft + 32;
  final contentWidth = screenWidth - 64;

  switch (screenIdx) {
    case 1:
      _paintHubContent(canvas, contentLeft, contentTop, contentWidth);
      break;
    case 2:
      _paintOfflineContent(canvas, contentLeft, contentTop, contentWidth);
      break;
    case 3:
      _paintDailyCourseContent(canvas, contentLeft, contentTop, contentWidth);
      break;
    case 4:
      _paintMemoryContent(canvas, contentLeft, contentTop, contentWidth);
      break;
    case 5:
      _paintHanoiContent(canvas, contentLeft, contentTop, contentWidth);
      break;
    case 6:
      _paintMathContent(canvas, contentLeft, contentTop, contentWidth);
      break;
    case 7:
      _paintReflexContent(canvas, contentLeft, contentTop, contentWidth);
      break;
    case 8:
    default:
      _paintStatsContent(canvas, contentLeft, contentTop, contentWidth);
      break;
  }
}

// 1. Hub / Category Grid
void _paintHubContent(Canvas canvas, double left, double top, double width) {
  final categories = [
    ('Mantık & Çözüm', const Color(0xFF665AA2), '14 Oyun'),
    ('Sayılar & Matematik', const Color(0xFF176D62), '12 Oyun'),
    ('Görsel & Uzamsal', const Color(0xFF9C5471), '10 Oyun'),
    ('Hafıza & Dikkat', const Color(0xFF8B622C), '11 Oyun'),
    ('Planlama & Strateji', const Color(0xFFA2643E), '12 Oyun'),
    ('Hız & Refleks', const Color(0xFFA84640), '10 Oyun'),
    ('Dil & Kelime', const Color(0xFF3D7183), '8 Oyun'),
    ('Eğlence Oyunları', const Color(0xFF087FA8), '7 Oyun'),
  ];

  const colWidth = 385.0;
  const rowHeight = 175.0;
  const gap = 20.0;

  for (int i = 0; i < 8; i++) {
    final col = i % 2;
    final row = i ~/ 2;
    final x = left + col * (colWidth + gap);
    final y = top + row * (rowHeight + gap);
    final cat = categories[i];

    final cardRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, colWidth, rowHeight),
      const Radius.circular(22),
    );
    canvas.drawRRect(cardRRect, Paint()..color = const Color(0xFF1E293B));
    canvas.drawRRect(
      cardRRect,
      Paint()
        ..color = cat.$2.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Icon Circle
    canvas.drawCircle(Offset(x + 42, y + 50), 24, Paint()..color = cat.$2.withValues(alpha: 0.3));
    canvas.drawCircle(Offset(x + 42, y + 50), 12, Paint()..color = cat.$2);

    // Text
    final titleTp = TextPainter(
      text: TextSpan(
        text: cat.$1,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: colWidth - 32);
    titleTp.paint(canvas, Offset(x + 20, y + 96));

    final countTp = TextPainter(
      text: TextSpan(
        text: cat.$3,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.6),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    countTp.paint(canvas, Offset(x + 20, y + 132));
  }
}

// 2. Offline Mode Screen
void _paintOfflineContent(Canvas canvas, double left, double top, double width) {
  // Offline Banner
  final bannerRRect = RRect.fromRectAndRadius(
    Rect.fromLTWH(left, top, width, 140),
    const Radius.circular(22),
  );
  canvas.drawRRect(
    bannerRRect,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(left, top),
        Offset(left + width, top + 140),
        [const Color(0xFF065F46), const Color(0xFF047857)],
      ),
  );

  final banTitle = TextPainter(
    text: const TextSpan(
      text: '✈ %100 Çevrimdışı & Reklamsız',
      style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  banTitle.paint(canvas, Offset(left + 24, top + 34));

  final banSub = TextPainter(
    text: const TextSpan(
      text: 'İnternet bağlantısı, kota ve reklam olmadan kesintisiz oyna',
      style: TextStyle(color: Colors.white70, fontSize: 18),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  banSub.paint(canvas, Offset(left + 24, top + 80));

  // 4 Game Cards
  final games = [
    ('Satranç Klasik', 'Strateji • Çevrimdışı', const Color(0xFFA2643E)),
    ('Hanoi Kulesi', 'Mantık • Çevrimdışı', const Color(0xFF087FA8)),
    ('2048 Birleştir', 'Sayısal • Çevrimdışı', const Color(0xFF176D62)),
    ('Sudoku Mini', 'Matematik • Çevrimdışı', const Color(0xFF2457A6)),
  ];

  double cardY = top + 170;
  for (final g in games) {
    final cr = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, cardY, width, 110),
      const Radius.circular(20),
    );
    canvas.drawRRect(cr, Paint()..color = const Color(0xFF1E293B));
    canvas.drawRRect(
      cr,
      Paint()
        ..color = g.$3.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Color Badge
    canvas.drawCircle(Offset(left + 48, cardY + 55), 26, Paint()..color = g.$3.withValues(alpha: 0.25));
    canvas.drawCircle(Offset(left + 48, cardY + 55), 14, Paint()..color = g.$3);

    // Title & Tag
    final tTp = TextPainter(
      text: TextSpan(
        text: g.$1,
        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tTp.paint(canvas, Offset(left + 96, cardY + 28));

    final tagTp = TextPainter(
      text: TextSpan(
        text: g.$2,
        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tagTp.paint(canvas, Offset(left + 96, cardY + 62));

    // Play button
    final btnR = RRect.fromRectAndRadius(
      Rect.fromLTWH(left + width - 130, cardY + 32, 106, 46),
      const Radius.circular(14),
    );
    canvas.drawRRect(btnR, Paint()..color = g.$3);

    final btnTp = TextPainter(
      text: const TextSpan(
        text: 'OYNA',
        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    btnTp.paint(canvas, Offset(left + width - 98, cardY + 44));

    cardY += 130;
  }
}

// 3. Daily Course Screen
void _paintDailyCourseContent(Canvas canvas, double left, double top, double width) {
  // Streak Banner
  final stR = RRect.fromRectAndRadius(
    Rect.fromLTWH(left, top, width, 130),
    const Radius.circular(22),
  );
  canvas.drawRRect(
    stR,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(left, top),
        Offset(left + width, top + 130),
        [const Color(0xFF78350F), const Color(0xFFB45309)],
      ),
  );

  final stTitle = TextPainter(
    text: const TextSpan(
      text: '🔥 7 Günlük Antrenman Serisi!',
      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  stTitle.paint(canvas, Offset(left + 24, top + 30));

  final stSub = TextPainter(
    text: const TextSpan(
      text: 'Her gün 3 özel zeka egzersizi ile zihnini keskin tut',
      style: TextStyle(color: Colors.white70, fontSize: 17),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  stSub.paint(canvas, Offset(left + 24, top + 72));

  // 3 Daily Rounds
  final rounds = [
    ('1. Tur: Kart Eşleme', 'Hafıza Egzersizi', '✓ TAMAMLANDI', Colors.green),
    ('2. Tur: Hızlı 24', 'Sayısal Zeka', '▶ ŞİMDİ OYNA', const Color(0xFFF59E0B)),
    ('3. Tur: Hanoi Kulesi', 'Mantık & Strateji', '🔒 KİLİTLİ', Colors.grey),
  ];

  double rY = top + 160;
  for (final r in rounds) {
    final cr = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, rY, width, 120),
      const Radius.circular(20),
    );
    canvas.drawRRect(cr, Paint()..color = const Color(0xFF1E293B));
    canvas.drawRRect(
      cr,
      Paint()
        ..color = r.$4.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    final titleTp = TextPainter(
      text: TextSpan(
        text: r.$1,
        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    titleTp.paint(canvas, Offset(left + 28, rY + 30));

    final subTp = TextPainter(
      text: TextSpan(
        text: r.$2,
        style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 16),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    subTp.paint(canvas, Offset(left + 28, rY + 68));

    // Status pill
    final stPill = RRect.fromRectAndRadius(
      Rect.fromLTWH(left + width - 170, rY + 40, 146, 40),
      const Radius.circular(14),
    );
    canvas.drawRRect(stPill, Paint()..color = r.$4.withValues(alpha: 0.2));

    final stTp = TextPainter(
      text: TextSpan(
        text: r.$3,
        style: TextStyle(color: r.$4, fontSize: 14, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    stTp.paint(canvas, Offset(left + width - 158, rY + 50));

    rY += 150;
  }
}

// 4. Memory Match Screen
void _paintMemoryContent(Canvas canvas, double left, double top, double width) {
  const cols = 3;
  final cardW = (width - 40) / cols;
  const cardH = 175.0;

  final cards = [
    (true, '🧠', const Color(0xFFEC4899)),
    (false, '?', Colors.white24),
    (false, '?', Colors.white24),
    (true, '🧠', const Color(0xFFEC4899)),
    (false, '?', Colors.white24),
    (true, '★', const Color(0xFFF59E0B)),
    (false, '?', Colors.white24),
    (true, '★', const Color(0xFFF59E0B)),
    (false, '?', Colors.white24),
    (false, '?', Colors.white24),
    (false, '?', Colors.white24),
    (false, '?', Colors.white24),
  ];

  for (int i = 0; i < 12; i++) {
    final col = i % cols;
    final row = i ~/ cols;
    final x = left + col * (cardW + 20);
    final y = top + row * (cardH + 20);
    final c = cards[i];

    final cr = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, cardW, cardH),
      const Radius.circular(20),
    );

    if (c.$1) {
      canvas.drawRRect(
        cr,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(x, y),
            Offset(x + cardW, y + cardH),
            [c.$3.withValues(alpha: 0.8), c.$3],
          ),
      );
      canvas.drawRRect(
        cr,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    } else {
      canvas.drawRRect(cr, Paint()..color = const Color(0xFF1E293B));
      canvas.drawRRect(
        cr,
        Paint()
          ..color = const Color(0xFF475569)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    final symbolTp = TextPainter(
      text: TextSpan(
        text: c.$2,
        style: TextStyle(
          color: c.$1 ? Colors.white : Colors.white38,
          fontSize: 44,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    symbolTp.paint(
      canvas,
      Offset(x + (cardW - symbolTp.width) / 2, y + (cardH - symbolTp.height) / 2),
    );
  }
}

// 5. Hanoi / Logic Screen
void _paintHanoiContent(Canvas canvas, double left, double top, double width) {
  // 3 Pegs
  final pegW = 12.0;
  final pegH = 340.0;
  final baseY = top + 420;

  final pegX = [
    left + width * 0.2,
    left + width * 0.5,
    left + width * 0.8,
  ];

  for (final px in pegX) {
    // Pole
    final poleR = RRect.fromRectAndRadius(
      Rect.fromLTWH(px - pegW / 2, baseY - pegH, pegW, pegH),
      const Radius.circular(6),
    );
    canvas.drawRRect(poleR, Paint()..color = const Color(0xFF64748B));

    // Base
    final baseR = RRect.fromRectAndRadius(
      Rect.fromLTWH(px - 100, baseY, 200, 24),
      const Radius.circular(12),
    );
    canvas.drawRRect(baseR, Paint()..color = const Color(0xFF334155));
  }

  // Peg 1 Rings
  final ringsPeg1 = [
    (180.0, const Color(0xFF10B981)),
    (140.0, const Color(0xFFF59E0B)),
    (100.0, const Color(0xFFEF4444)),
  ];

  double rY = baseY - 36;
  for (final r in ringsPeg1) {
    final rr = RRect.fromRectAndRadius(
      Rect.fromLTWH(pegX[0] - r.$1 / 2, rY, r.$1, 32),
      const Radius.circular(16),
    );
    canvas.drawRRect(rr, Paint()..color = r.$2);
    rY -= 38;
  }

  // Peg 2 Ring
  final rr2 = RRect.fromRectAndRadius(
    Rect.fromLTWH(pegX[1] - 70 / 2, baseY - 36, 70, 32),
    const Radius.circular(16),
  );
  canvas.drawRRect(rr2, Paint()..color = const Color(0xFF6366F1));

  // Control Buttons at bottom
  final ctrlY = baseY + 70;
  final btnBoxR = RRect.fromRectAndRadius(
    Rect.fromLTWH(left, ctrlY, width, 80),
    const Radius.circular(20),
  );
  canvas.drawRRect(btnBoxR, Paint()..color = const Color(0xFF1E293B));
  canvas.drawRRect(
    btnBoxR,
    Paint()
      ..color = const Color(0xFF0EA5E9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5,
  );

  final ctrlTp = TextPainter(
    text: const TextSpan(
      text: '↩ Geri Al           💡 İpucu           ↻ Yeniden',
      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  ctrlTp.paint(canvas, Offset(left + (width - ctrlTp.width) / 2, ctrlY + 26));
}

// 6. Math 2048 Screen
void _paintMathContent(Canvas canvas, double left, double top, double width) {
  const cols = 3;
  final tileW = (width - 40) / cols;
  final tileH = tileW;

  final tiles = [
    (1024, const Color(0xFFEDC22E), Colors.white),
    (512, const Color(0xFFEDC850), Colors.white),
    (256, const Color(0xFFEDCC61), Colors.white),
    (128, const Color(0xFFEDCF72), Colors.white),
    (64, const Color(0xFFF65E3B), Colors.white),
    (32, const Color(0xFFF67C5F), Colors.white),
    (16, const Color(0xFFF59563), Colors.white),
    (8, const Color(0xFFF2B179), Colors.white),
    (4, const Color(0xFFEDE0C8), const Color(0xFF776E65)),
    (2, const Color(0xFFEEE4DA), const Color(0xFF776E65)),
    (0, const Color(0xFF1E293B), Colors.transparent),
    (0, const Color(0xFF1E293B), Colors.transparent),
  ];

  for (int i = 0; i < 12; i++) {
    final col = i % cols;
    final row = i ~/ cols;
    final x = left + col * (tileW + 20);
    final y = top + row * (tileH + 20);
    final t = tiles[i];

    final tr = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, tileW, tileH),
      const Radius.circular(20),
    );
    canvas.drawRRect(tr, Paint()..color = t.$2);

    if (t.$1 > 0) {
      final numTp = TextPainter(
        text: TextSpan(
          text: '${t.$1}',
          style: TextStyle(
            color: t.$3,
            fontSize: t.$1 >= 1000 ? 34 : 40,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      numTp.paint(
        canvas,
        Offset(x + (tileW - numTp.width) / 2, y + (tileH - numTp.height) / 2),
      );
    }
  }
}

// 7. Reflex Screen
void _paintReflexContent(Canvas canvas, double left, double top, double width) {
  final cx = left + width / 2;
  final cy = top + 260;

  // Outer Pulse Ring
  canvas.drawCircle(
    Offset(cx, cy),
    220,
    Paint()
      ..color = const Color(0xFFEF4444).withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
  );

  // Main Red Target Circle
  final targetPaint = Paint()
    ..shader = ui.Gradient.radial(
      Offset(cx, cy),
      170,
      [const Color(0xFFEF4444), const Color(0xFF991B1B)],
    );
  canvas.drawCircle(Offset(cx, cy), 170, targetPaint);

  // Millisecond text
  final msTp = TextPainter(
    text: const TextSpan(
      text: '184 ms',
      style: TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w900),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  msTp.paint(canvas, Offset(cx - msTp.width / 2, cy - 35));

  final resTp = TextPainter(
    text: const TextSpan(
      text: '⚡ MÜKEMMEL TEPKİ',
      style: TextStyle(
        color: Colors.white70,
        fontSize: 22,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  resTp.paint(canvas, Offset(cx - resTp.width / 2, cy + 30));

  // Bottom Ranking Pill
  final pillR = RRect.fromRectAndRadius(
    Rect.fromLTWH(left + 40, cy + 240, width - 80, 70),
    const Radius.circular(35),
  );
  canvas.drawRRect(pillR, Paint()..color = const Color(0xFF1E293B));
  canvas.drawRRect(
    pillR,
    Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2,
  );

  final rankTp = TextPainter(
    text: const TextSpan(
      text: 'En Hızlı %1 Dilimindesiniz 🏆',
      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  rankTp.paint(canvas, Offset(cx - rankTp.width / 2, cy + 258));
}

// 8. Cognitive Stats Screen
void _paintStatsContent(Canvas canvas, double left, double top, double width) {
  // Top Stats Overview Box
  final boxR = RRect.fromRectAndRadius(
    Rect.fromLTWH(left, top, width, 120),
    const Radius.circular(22),
  );
  canvas.drawRRect(
    boxR,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(left, top),
        Offset(left + width, top + 120),
        [const Color(0xFF0F766E), const Color(0xFF14B8A6)],
      ),
  );

  final s1 = TextPainter(
    text: const TextSpan(
      text: '1480\nBeyin Skoru',
      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, height: 1.3),
    ),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
  )..layout();
  s1.paint(canvas, Offset(left + width * 0.1, top + 34));

  final s2 = TextPainter(
    text: const TextSpan(
      text: '142\nOyun',
      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, height: 1.3),
    ),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
  )..layout();
  s2.paint(canvas, Offset(left + width * 0.45, top + 34));

  final s3 = TextPainter(
    text: const TextSpan(
      text: 'Usta\nSeviye 24',
      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, height: 1.3),
    ),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
  )..layout();
  s3.paint(canvas, Offset(left + width * 0.72, top + 34));

  // 5 Skill Bars
  final stats = [
    ('Hafıza & Bellek', 0.92, const Color(0xFFEC4899)),
    ('Mantık & Problem', 0.88, const Color(0xFF6366F1)),
    ('Sayısal Zeka', 0.84, const Color(0xFF10B981)),
    ('Odaklanma & Dikkat', 0.95, const Color(0xFFF59E0B)),
    ('Hız & Refleks', 0.90, const Color(0xFFEF4444)),
  ];

  double bY = top + 160;
  for (final s in stats) {
    final labelTp = TextPainter(
      text: TextSpan(
        text: s.$1,
        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    labelTp.paint(canvas, Offset(left, bY));

    final pctTp = TextPainter(
      text: TextSpan(
        text: '%${(s.$2 * 100).toInt()}',
        style: TextStyle(color: s.$3, fontSize: 22, fontWeight: FontWeight.w900),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    pctTp.paint(canvas, Offset(left + width - pctTp.width, bY));

    bY += 34;

    // Track
    final trackR = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, bY, width, 18),
      const Radius.circular(9),
    );
    canvas.drawRRect(trackR, Paint()..color = const Color(0xFF334155));

    // Fill
    final fillR = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, bY, width * s.$2, 18),
      const Radius.circular(9),
    );
    canvas.drawRRect(fillR, Paint()..color = s.$3);

    bY += 46;
  }
}

ScreenData _getScreenData(String lang, int idx) {
  switch (lang) {
    case 'tr':
      return switch (idx) {
        1 => const ScreenData(
            badge: '✦ 80+ AKIL OYUNU',
            title: 'TÜM ZEKA OYUNLARI\nTEK UYGULAMADA',
            subtitle: 'Mantık, hafıza, matematik ve refleks parkurları',
            accentColor: Color(0xFF6366F1),
            secondaryColor: Color(0xFF8B5CF6),
            phoneHeaderTitle: 'Zeka Parkuru Hub',
            phoneSubHeader: '8 Kategori • 84 Zeka Oyunu',
          ),
        2 => const ScreenData(
            badge: '⚡ %100 İNTERNETSİZ & REKLAMSIZ',
            title: 'HER YERDE KESİNTİSİZ\nÇEVRİMDIŞI OYNA',
            subtitle: 'Metroda, uçakta, seyahatte sıfır reklam ile tam odaklan',
            accentColor: Color(0xFF10B981),
            secondaryColor: Color(0xFF059669),
            phoneHeaderTitle: 'Çevrimdışı Mod Aktif',
            phoneSubHeader: 'Sıfır İnternet Kotası • Reklamsız',
          ),
        3 => const ScreenData(
            badge: '📅 KİŞİSEL BEYİN ANTRENMANI',
            title: 'GÜNLÜK BEYİN\nPARKURU VE RUTİNİ',
            subtitle: 'Her gün 3 özel zeka egzersizi ile zihnini keskin tut',
            accentColor: Color(0xFFF59E0B),
            secondaryColor: Color(0xFFD97706),
            phoneHeaderTitle: 'Günün Beyin Parkuru',
            phoneSubHeader: '3 Tur • Seri: 7 Gün Kesintisiz',
          ),
        4 => const ScreenData(
            badge: '🧠 GÖRSEL & SAYISAL BELLEK',
            title: 'GÜÇLÜ HAFIZA VE\nKONSANTRASYON',
            subtitle: 'Kart eşleme, sayı hafızası ve görsel desen testleri',
            accentColor: Color(0xFFEC4899),
            secondaryColor: Color(0xFFDB2777),
            phoneHeaderTitle: 'Hafıza Kartları Arenası',
            phoneSubHeader: 'Süre: 00:42 • Kombo: x3',
          ),
        5 => const ScreenData(
            badge: '♟️ STRATEJİ & PROBLEM ÇÖZME',
            title: 'MANTIK, SATRANÇ\nVE HANOİ KULESİ',
            subtitle: 'Taktiksel hamleleri planla, analitik düşünme gücünü geliştir',
            accentColor: Color(0xFF0EA5E9),
            secondaryColor: Color(0xFF0284C7),
            phoneHeaderTitle: 'Hanoi Kulesi Ustası',
            phoneSubHeader: 'Hamle: 5 / 7 • Minimum Hamle',
          ),
        6 => const ScreenData(
            badge: '🔢 SAYISAL ZEKA & HESAPLAMA',
            title: 'MATEMATİK VE\nSAYI BULMACALARI',
            subtitle: '2048, Hızlı 24, Sayı Ustası ve pratik zihinden işlemler',
            accentColor: Color(0xFF8B5CF6),
            secondaryColor: Color(0xFF6D28D9),
            phoneHeaderTitle: '2048 & Sayı Matrisi',
            phoneSubHeader: 'Skor: 14.280 • Hedef: 2048',
          ),
        7 => const ScreenData(
            badge: '⚡ MİLİSANİYELİK HASSASİYET',
            title: 'YÜKSEK DİKKAT VE\nHIZLI REFLEKS',
            subtitle: 'Tepki süreni milisaniyelerle ölç, hızını ve odağını kanıtla',
            accentColor: Color(0xFFEF4444),
            secondaryColor: Color(0xFFDC2626),
            phoneHeaderTitle: 'Refleks & Reaksiyon Avı',
            phoneSubHeader: 'Tepki Süresi: 184 ms • Mükemmel!',
          ),
        _ => const ScreenData(
            badge: '📊 BİLİŞSEL GELİŞİM TAKİBİ',
            title: 'DETAYLI BEYİN SKORU\nVE İSTATİSTİKLER',
            subtitle: '5 temel bilişsel alanda gelişimini grafiklerle takip et',
            accentColor: Color(0xFF14B8A6),
            secondaryColor: Color(0xFF0D9488),
            phoneHeaderTitle: 'Beyin Performans Profili',
            phoneSubHeader: 'Genel Skor: 1480 • Usta Seviye',
          ),
      };

    case 'en':
      return switch (idx) {
        1 => const ScreenData(
            badge: '✦ 80+ MIND GAMES',
            title: 'ALL BRAIN PUZZLES\nIN ONE APP',
            subtitle: 'Complete logic, memory, math and reflex gym',
            accentColor: Color(0xFF6366F1),
            secondaryColor: Color(0xFF8B5CF6),
            phoneHeaderTitle: 'Mind Park Hub',
            phoneSubHeader: '8 Categories • 84 Brain Games',
          ),
        2 => const ScreenData(
            badge: '⚡ 100% OFFLINE & AD-FREE',
            title: 'PLAY ANYWHERE\nWITHOUT INTERNET',
            subtitle: 'Subway, flight, travel with zero ads and deep focus',
            accentColor: Color(0xFF10B981),
            secondaryColor: Color(0xFF059669),
            phoneHeaderTitle: 'Offline Mode Active',
            phoneSubHeader: 'Zero Data Usage • No Popups',
          ),
        3 => const ScreenData(
            badge: '📅 PERSONALIZED ROUTINE',
            title: 'DAILY BRAIN\nTRAINING CIRCUIT',
            subtitle: '3 curated daily workouts to keep your mind sharp',
            accentColor: Color(0xFFF59E0B),
            secondaryColor: Color(0xFFD97706),
            phoneHeaderTitle: 'Daily Brain Circuit',
            phoneSubHeader: '3 Rounds • 7 Days Streak',
          ),
        4 => const ScreenData(
            badge: '🧠 VISUAL & WORKING MEMORY',
            title: 'BOOST MEMORY AND\nCONCENTRATION',
            subtitle: 'Card match, number recall and spatial pattern retention',
            accentColor: Color(0xFFEC4899),
            secondaryColor: Color(0xFFDB2777),
            phoneHeaderTitle: 'Memory Match Arena',
            phoneSubHeader: 'Time: 00:42 • Combo: x3',
          ),
        5 => const ScreenData(
            badge: '♟️ TACTICS & PROBLEM SOLVING',
            title: 'LOGIC, CHESS &\nTOWER OF HANOI',
            subtitle: 'Master strategy, critical thinking and puzzle solving',
            accentColor: Color(0xFF0EA5E9),
            secondaryColor: Color(0xFF0284C7),
            phoneHeaderTitle: 'Tower of Hanoi Master',
            phoneSubHeader: 'Moves: 5 / 7 • Optimal Route',
          ),
        6 => const ScreenData(
            badge: '🔢 SPEED ARITHMETIC & NUMBERS',
            title: 'MENTAL MATH &\nNUMBER PUZZLES',
            subtitle: '2048 fusion, Target 24 and rapid arithmetic challenges',
            accentColor: Color(0xFF8B5CF6),
            secondaryColor: Color(0xFF6D28D9),
            phoneHeaderTitle: '2048 & Number Grid',
            phoneSubHeader: 'Score: 14,280 • Target: 2048',
          ),
        7 => const ScreenData(
            badge: '⚡ MILLISECOND ACCURACY',
            title: 'HIGH FOCUS AND\nLIGHTNING REFLEX',
            subtitle: 'Measure reaction time in milliseconds and boost speed',
            accentColor: Color(0xFFEF4444),
            secondaryColor: Color(0xFFDC2626),
            phoneHeaderTitle: 'Reaction Time Hunt',
            phoneSubHeader: 'Reaction: 184 ms • Perfect Tap!',
          ),
        _ => const ScreenData(
            badge: '📊 COGNITIVE PROGRESS',
            title: 'DETAILED BRAIN SCORE\n& PERFORMANCE STATS',
            subtitle: 'Track your cognitive evolution across 5 key skill domains',
            accentColor: Color(0xFF14B8A6),
            secondaryColor: Color(0xFF0D9488),
            phoneHeaderTitle: 'Cognitive Brain Profile',
            phoneSubHeader: 'Overall Score: 1480 • Master Level',
          ),
      };

    case 'ar':
      return switch (idx) {
        1 => const ScreenData(
            badge: '✦ أكثر من 80 لعبة عقل',
            title: 'جميع ألعاب الذكاء\nفي تطبيق واحد',
            subtitle: 'منطق، ذاكرة، رياضيات وسرعة بديهة في مكان واحد',
            accentColor: Color(0xFF6366F1),
            secondaryColor: Color(0xFF8B5CF6),
            phoneHeaderTitle: 'مركز مضمار الذكاء',
            phoneSubHeader: '8 أقسام • 84 لعبة عقلية',
          ),
        2 => const ScreenData(
            badge: '⚡ 100% بدون إنترنت وبدون إعلانات',
            title: 'العب في أي مكان\nبدون نت نهائياً',
            subtitle: 'في الطائرة والمترو بتركيز كامل وبلا مقاطعة إعلانية',
            accentColor: Color(0xFF10B981),
            secondaryColor: Color(0xFF059669),
            phoneHeaderTitle: 'وضع الأوفلاين نشط',
            phoneSubHeader: 'بدون استهلاك بيانات • بدون إعلانات',
          ),
        3 => const ScreenData(
            badge: '📅 برنامج تدريب شخصي',
            title: 'تمرين عقلي يومي\nلتنشيط الذهن',
            subtitle: '3 جولات تدريبية كل يوم لشحذ فصوص الدماغ',
            accentColor: Color(0xFFF59E0B),
            secondaryColor: Color(0xFFD97706),
            phoneHeaderTitle: 'المضمار اليومي',
            phoneSubHeader: '3 جولات • سلسلة متصلة: 7 أيام',
          ),
        4 => const ScreenData(
            badge: '🧠 الذاكرة البصرية والرقمية',
            title: 'تقوية الذاكرة\nوالتركيز العالي',
            subtitle: 'مطابقة البطاقات، حفظ سلاسل الأرقام وتذكر الأنماط',
            accentColor: Color(0xFFEC4899),
            secondaryColor: Color(0xFFDB2777),
            phoneHeaderTitle: 'حلبة مطابقة الذاكرة',
            phoneSubHeader: 'الوقت: 00:42 • كومبو: x3',
          ),
        5 => const ScreenData(
            badge: '♟️ التخطيط الاستراتيجي',
            title: 'ألغاز المنطق،\nالشطرنج وأبراج هانوي',
            subtitle: 'خطط لتحركاتك بذكاء وحل أعقد المسائل المنطقية',
            accentColor: Color(0xFF0EA5E9),
            secondaryColor: Color(0xFF0284C7),
            phoneHeaderTitle: 'خبير أبراج هانوي',
            phoneSubHeader: 'الحركات: 5 / 7 • المسار الأمثل',
          ),
        6 => const ScreenData(
            badge: '🔢 الحساب الذهني السريع',
            title: 'ذكاء الأرقام\nوتحديات الرياضيات',
            subtitle: 'لعبة 2048، هدف 24 وألغاز العمليات الحسابية الذهنية',
            accentColor: Color(0xFF8B5CF6),
            secondaryColor: Color(0xFF6D28D9),
            phoneHeaderTitle: '2048 وشبكة الأرقام',
            phoneSubHeader: 'النتيجة: 14,280 • الهدف: 2048',
          ),
        7 => const ScreenData(
            badge: '⚡ سرعة استجابة خاطفة',
            title: 'قمة التركيز\nوسرعة البديهة',
            subtitle: 'قِس زمن رد فعلك العصبي بجزء من الثانية بدقة',
            accentColor: Color(0xFFEF4444),
            secondaryColor: Color(0xFFDC2626),
            phoneHeaderTitle: 'تحدي سرعة الاستجابة',
            phoneSubHeader: 'زمن الرد: 184 ميلي ثانية • رائع!',
          ),
        _ => const ScreenData(
            badge: '📊 تقييم القدرات المعرفية',
            title: 'معدل الذكاء\nوالإحصائيات الشاملة',
            subtitle: 'تابع تطور مستواك في 5 مهارات عقلية أساسية',
            accentColor: Color(0xFF14B8A6),
            secondaryColor: Color(0xFF0D9488),
            phoneHeaderTitle: 'ملف الأداء العقلي',
            phoneSubHeader: 'المعدل العام: 1480 • مستوى أستاذ',
          ),
      };

    case 'id':
      return switch (idx) {
        1 => const ScreenData(
            badge: '✦ 80+ GAME ASAH OTAK',
            title: 'SEMUA GAME LOGIKA\nDALAM SATU APLIKASI',
            subtitle: 'Asah logika, memori, matematika dan refleks kilat',
            accentColor: Color(0xFF6366F1),
            secondaryColor: Color(0xFF8B5CF6),
            phoneHeaderTitle: 'Arena Otak Hub',
            phoneSubHeader: '8 Kategori • 84 Game Lengkap',
          ),
        2 => const ScreenData(
            badge: '⚡ 100% OFFLINE & BEBAS IKLAN',
            title: 'MAIN DI MANA SAJA\nTANPA KUOTA INTERNET',
            subtitle: 'Di KRL, pesawat, mudik tanpa iklan video mengganggu',
            accentColor: Color(0xFF10B981),
            secondaryColor: Color(0xFF059669),
            phoneHeaderTitle: 'Mode Offline Aktif',
            phoneSubHeader: 'Hemat Kuota • Tanpa Iklan',
          ),
        3 => const ScreenData(
            badge: '📅 LATIHAN TERJADWAL',
            title: 'SENAM OTAK HARIAN\nLEBIH EFEKTIF',
            subtitle: '3 babak latihan setiap hari agar pikiran tetap tajam',
            accentColor: Color(0xFFF59E0B),
            secondaryColor: Color(0xFFD97706),
            phoneHeaderTitle: 'Sirkuit Otak Harian',
            phoneSubHeader: '3 Babak • Runtun: 7 Hari',
          ),
        4 => const ScreenData(
            badge: '🧠 DAYA INGAT VISUAL',
            title: 'TINGKATKAN MEMORI\nDAN KONSENTRASI',
            subtitle: 'Buka kartu kembar, ingat urutan angka dan pola',
            accentColor: Color(0xFFEC4899),
            secondaryColor: Color(0xFFDB2777),
            phoneHeaderTitle: 'Arena Kartu Memori',
            phoneSubHeader: 'Waktu: 00:42 • Kombo: x3',
          ),
        5 => const ScreenData(
            badge: '♟️ STRATEGI & TAKTIK',
            title: 'LOGIKA, CATUR DAN\nMENARA HANOI',
            subtitle: 'Rancang langkah cerdas, pecahkan teka-teki sulit',
            accentColor: Color(0xFF0EA5E9),
            secondaryColor: Color(0xFF0284C7),
            phoneHeaderTitle: 'Master Menara Hanoi',
            phoneSubHeader: 'Langkah: 5 / 7 • Jalur Optimal',
          ),
        6 => const ScreenData(
            badge: '🔢 HITUNG CEPAT & ANGKA',
            title: 'KECERDASAN ANGKA\n& PUZZLE MATEMATIKA',
            subtitle: 'Gabung 2048, Target 24 dan aritmatika kilat',
            accentColor: Color(0xFF8B5CF6),
            secondaryColor: Color(0xFF6D28D9),
            phoneHeaderTitle: '2048 & Kisi Angka',
            phoneSubHeader: 'Skor: 14.280 • Target: 2048',
          ),
        7 => const ScreenData(
            badge: '⚡ WAKTU REAKSI MILIDETIK',
            title: 'FOKUS TINGGI DAN\nREFLEKS KILAT',
            subtitle: 'Uji kecepatan respon tangan, buktikan ketajaman matamu',
            accentColor: Color(0xFFEF4444),
            secondaryColor: Color(0xFFDC2626),
            phoneHeaderTitle: 'Tantangan Reaksi Cepat',
            phoneSubHeader: 'Respon: 184 ms • Luar Biasa!',
          ),
        _ => const ScreenData(
            badge: '📊 SKOR PERFORMA OTAK',
            title: 'GRAFIK KEMAJUAN\n& STATISTIK LENGKAP',
            subtitle: 'Pantau perkembangan di 5 bidang kognitif utama',
            accentColor: Color(0xFF14B8A6),
            secondaryColor: Color(0xFF0D9488),
            phoneHeaderTitle: 'Profil Kognitif Otak',
            phoneSubHeader: 'Skor Total: 1480 • Level Master',
          ),
      };

    case 'pt':
      return switch (idx) {
        1 => const ScreenData(
            badge: '✦ +80 JOGOS MENTAIS',
            title: 'TODOS OS JOGOS DE LÓGICA\nEM UM SÓ LUGAR',
            subtitle: 'Raciocínio, memória, matemática e reflexos rápidos',
            accentColor: Color(0xFF6366F1),
            secondaryColor: Color(0xFF8B5CF6),
            phoneHeaderTitle: 'Central Treino Cerebral',
            phoneSubHeader: '8 Categorias • 84 Jogos',
          ),
        2 => const ScreenData(
            badge: '⚡ 100% OFFLINE & SEM ANÚNCIOS',
            title: 'JOGUE ONDE QUISER\nSEM GASTAR INTERNET',
            subtitle: 'No metrô, no avião com zero anúncios em vídeo',
            accentColor: Color(0xFF10B981),
            secondaryColor: Color(0xFF059669),
            phoneHeaderTitle: 'Modo Offline Ativo',
            phoneSubHeader: 'Zero Dados • Sem Anúncios',
          ),
        3 => const ScreenData(
            badge: '📅 CIRCUITO PERSONALIZADO',
            title: 'TREINO CEREBRAL\nDIÁRIO E COMPLETO',
            subtitle: '3 fases diárias para manter seus neurônios ativos',
            accentColor: Color(0xFFF59E0B),
            secondaryColor: Color(0xFFD97706),
            phoneHeaderTitle: 'Circuito Mental Diário',
            phoneSubHeader: '3 Etapas • Sequência: 7 Dias',
          ),
        4 => const ScreenData(
            badge: '🧠 MEMÓRIA VISUAL E OPERACIONAL',
            title: 'FORTALEÇA SUA MEMÓRIA\nE CONCENTRAÇÃO',
            subtitle: 'Jogo da memória, sequências de números e padrões',
            accentColor: Color(0xFFEC4899),
            secondaryColor: Color(0xFFDB2777),
            phoneHeaderTitle: 'Arena Jogo da Memória',
            phoneSubHeader: 'Tempo: 00:42 • Combo: x3',
          ),
        5 => const ScreenData(
            badge: '♟️ TÁTICA E PENSAMENTO CRÍTICO',
            title: 'LÓGICA, XADREZ E\nTORRES DE HANÓI',
            subtitle: 'Planeje jogadas mestras e resolva quebra-cabeças',
            accentColor: Color(0xFF0EA5E9),
            secondaryColor: Color(0xFF0284C7),
            phoneHeaderTitle: 'Mestre da Torre de Hanói',
            phoneSubHeader: 'Movimentos: 5 / 7 • Rota Ideal',
          ),
        6 => const ScreenData(
            badge: '🔢 CÁLCULO MENTAL E NÚMEROS',
            title: 'RACIOCÍNIO NUMÉRICO\nE MATEMÁTICA',
            subtitle: 'Fusão 2048, Alvo 24 e cálculo mental rápido',
            accentColor: Color(0xFF8B5CF6),
            secondaryColor: Color(0xFF6D28D9),
            phoneHeaderTitle: '2048 & Matriz de Números',
            phoneSubHeader: 'Pontos: 14.280 • Alvo: 2048',
          ),
        7 => const ScreenData(
            badge: '⚡ REAÇÃO EM MILISSEGUNDOS',
            title: 'FOCO MÁXIMO E\nREFLEXOS RÁPIDOS',
            subtitle: 'Meça seu tempo de resposta com precisão milimétrica',
            accentColor: Color(0xFFEF4444),
            secondaryColor: Color(0xFFDC2626),
            phoneHeaderTitle: 'Desafio de Reflexo Rápido',
            phoneSubHeader: 'Tempo: 184 ms • Toque Perfeito!',
          ),
        _ => const ScreenData(
            badge: '📊 DESEMPENHO COGNITIVO',
            title: 'PONTUAÇÃO MENTAL\nE ESTATÍSTICAS REAIS',
            subtitle: 'Acompanhe seu avanço em 5 áreas fundamentais',
            accentColor: Color(0xFF14B8A6),
            secondaryColor: Color(0xFF0D9488),
            phoneHeaderTitle: 'Perfil Cognitivo Mental',
            phoneSubHeader: 'Pontuação: 1480 • Nível Mestre',
          ),
      };

    case 'es':
      return switch (idx) {
        1 => const ScreenData(
            badge: '✦ +80 JUEGOS DE INGENIO',
            title: 'TODOS LOS JUEGOS MENTALES\nEN UNA SOLA APP',
            subtitle: 'Lógica, memoria, cálculo mental y reflejos',
            accentColor: Color(0xFF6366F1),
            secondaryColor: Color(0xFF8B5CF6),
            phoneHeaderTitle: 'Centro Pista Mental',
            phoneSubHeader: '8 Categorías • 84 Juegos',
          ),
        2 => const ScreenData(
            badge: '⚡ 100% OFFLINE Y SIN ANUNCIOS',
            title: 'JUEGA EN CUALQUIER LUGAR\nSIN CONEXIÓN',
            subtitle: 'En el metro, en el avión con cero publicidad molesta',
            accentColor: Color(0xFF10B981),
            secondaryColor: Color(0xFF059669),
            phoneHeaderTitle: 'Modo Offline Activo',
            phoneSubHeader: 'Cero Datos • Sin Anuncios',
          ),
        3 => const ScreenData(
            badge: '📅 ENTRENAMIENTO PERSONALIZADO',
            title: 'GIMNASIA CEREBRAL\nDIARIA Y EFECTIVA',
            subtitle: '3 pruebas diarias para mantener tu mente despierta',
            accentColor: Color(0xFFF59E0B),
            secondaryColor: Color(0xFFD97706),
            phoneHeaderTitle: 'Circuito Mental Diario',
            phoneSubHeader: '3 Rondas • Racha: 7 Días',
          ),
        4 => const ScreenData(
            badge: '🧠 MEMORIA VISUAL Y ESPACIAL',
            title: 'POTENCIA TU MEMORIA\nY CONCENTRACIÓN',
            subtitle: 'Parejas de cartas, series de números y laberintos',
            accentColor: Color(0xFFEC4899),
            secondaryColor: Color(0xFFDB2777),
            phoneHeaderTitle: 'Arena Juego de Memoria',
            phoneSubHeader: 'Tiempo: 00:42 • Combo: x3',
          ),
        5 => const ScreenData(
            badge: '♟️ TÁCTICA Y PENSAMIENTO CRÍTICO',
            title: 'LÓGICA, AJEDREZ Y\nTORRES DE HANÓI',
            subtitle: 'Planea movimientos clave y resuelve problemas',
            accentColor: Color(0xFF0EA5E9),
            secondaryColor: Color(0xFF0284C7),
            phoneHeaderTitle: 'Maestro Torre de Hanói',
            phoneSubHeader: 'Movimientos: 5 / 7 • Ruta Óptima',
          ),
        6 => const ScreenData(
            badge: '🔢 CÁLCULO MENTAL Y NÚMEROS',
            title: 'INGENIO NUMÉRICO\nY MATEMÁTICAS',
            subtitle: 'Fusión 2048, Diana 24 y agilidad de cálculo ágil',
            accentColor: Color(0xFF8B5CF6),
            secondaryColor: Color(0xFF6D28D9),
            phoneHeaderTitle: '2048 & Matriz Numérica',
            phoneSubHeader: 'Puntos: 14.280 • Diana: 2048',
          ),
        7 => const ScreenData(
            badge: '⚡ REACCIÓN AL MILISEGUNDO',
            title: 'MÁXIMA ATENCIÓN Y\nREFLEJOS RÁPIDOS',
            subtitle: 'Mide tu tiempo de respuesta y agudeza mental',
            accentColor: Color(0xFFEF4444),
            secondaryColor: Color(0xFFDC2626),
            phoneHeaderTitle: 'Prueba de Reflejo Rápido',
            phoneSubHeader: 'Tiempo: 184 ms • ¡Toque Perfecto!',
          ),
        _ => const ScreenData(
            badge: '📊 RENDIMIENTO COGNITIVO',
            title: 'PUNTUACIÓN MENTAL\nY ESTADÍSTICAS REALES',
            subtitle: 'Sigue tu evolución en 5 habilidades cognitivas clave',
            accentColor: Color(0xFF14B8A6),
            secondaryColor: Color(0xFF0D9488),
            phoneHeaderTitle: 'Perfil Cognitivo Cerebral',
            phoneSubHeader: 'Puntuación: 1480 • Nivel Maestro',
          ),
      };

    case 'fr':
      return switch (idx) {
        1 => const ScreenData(
            badge: '✦ 80+ JEUX D\'ESPRIT',
            title: 'TOUS LES JEUX DE LOGIQUE\nEN UNE SEULE APPLICATION',
            subtitle: 'Réflexion, mémoire, maths et vivacité intellectuelle',
            accentColor: Color(0xFF6366F1),
            secondaryColor: Color(0xFF8B5CF6),
            phoneHeaderTitle: 'Hub Gym Cerveau',
            phoneSubHeader: '8 Catégories • 84 Jeux',
          ),
        2 => const ScreenData(
            badge: '⚡ 100% HORS-LIGNE & SANS PUB',
            title: 'JOUEZ N\'IMPORTE OÙ\nSANS FORFAIT INTERNET',
            subtitle: 'Dans le métro, en avion avec zéro publicité intrusive',
            accentColor: Color(0xFF10B981),
            secondaryColor: Color(0xFF059669),
            phoneHeaderTitle: 'Mode Hors-Ligne Actif',
            phoneSubHeader: 'Zéro Forfait • Sans Publicité',
          ),
        3 => const ScreenData(
            badge: '📅 CIRCUIT PERSONNALISÉ',
            title: 'ENTRAÎNEMENT CÉRÉBRAL\nQUOTIDIEN & COMPLET',
            subtitle: '3 épreuves par jour pour stimuler vos neurones',
            accentColor: Color(0xFFF59E0B),
            secondaryColor: Color(0xFFD97706),
            phoneHeaderTitle: 'Circuit Quotidien',
            phoneSubHeader: '3 Épreuves • Série: 7 Jours',
          ),
        4 => const ScreenData(
            badge: '🧠 MÉMOIRE VISUELLE & DE TRAVAIL',
            title: 'BOOSTEZ VOTRE MÉMOIRE\nET CONCENTRATION',
            subtitle: 'Cartes mémoire, suites de chiffres et motifs spatiaux',
            accentColor: Color(0xFFEC4899),
            secondaryColor: Color(0xFFDB2777),
            phoneHeaderTitle: 'Arène Cartes Mémoire',
            phoneSubHeader: 'Temps: 00:42 • Combo: x3',
          ),
        5 => const ScreenData(
            badge: '♟️ STRATÉGIE & ANTICIPATION',
            title: 'LOGIQUE, ÉCHECS ET\nTOURS DE HANOÏ',
            subtitle: 'Maîtrisez les tactiques et la résolution de casse-têtes',
            accentColor: Color(0xFF0EA5E9),
            secondaryColor: Color(0xFF0284C7),
            phoneHeaderTitle: 'Maître Tours de Hanoï',
            phoneSubHeader: 'Coups: 5 / 7 • Chemin Optimal',
          ),
        6 => const ScreenData(
            badge: '🔢 CALCUL MENTAL & CHIFFRES',
            title: 'AGILITÉ NUMÉRIQUE\nET MATHÉMATIQUES',
            subtitle: 'Fusion 2048, Défi 24 et arithmétique rapide',
            accentColor: Color(0xFF8B5CF6),
            secondaryColor: Color(0xFF6D28D9),
            phoneHeaderTitle: '2048 & Grille Numérique',
            phoneSubHeader: 'Score: 14 280 • Cible: 2048',
          ),
        7 => const ScreenData(
            badge: '⚡ RÉPONSE À LA MILLISECONDE',
            title: 'VIVACITÉ D\'ESPRIT ET\nRÉFLEXES ÉCLAIR',
            subtitle: 'Mesurez votre temps de réaction avec précision',
            accentColor: Color(0xFFEF4444),
            secondaryColor: Color(0xFFDC2626),
            phoneHeaderTitle: 'Test de Réflexes Vifs',
            phoneSubHeader: 'Réponse: 184 ms • Parfait!',
          ),
        _ => const ScreenData(
            badge: '📊 SUIVI COGNITIF AVANCÉ',
            title: 'SCORE CÉRÉBRAL DÉTAILLÉ\nET STATISTIQUES',
            subtitle: 'Visualisez vos progrès dans 5 domaines majeurs',
            accentColor: Color(0xFF14B8A6),
            secondaryColor: Color(0xFF0D9488),
            phoneHeaderTitle: 'Profil Cognitif Mental',
            phoneSubHeader: 'Score Global: 1480 • Niveau Maître',
          ),
      };

    case 'de':
    default:
      return switch (idx) {
        1 => const ScreenData(
            badge: '✦ 80+ DENKSPIELE',
            title: 'ALLE DENK- & LOGIKRÄTSEL\nIN EINER EINZIGEN APP',
            subtitle: 'Logik, Gedächtnis, Mathe und Blitzreflexe',
            accentColor: Color(0xFF6366F1),
            secondaryColor: Color(0xFF8B5CF6),
            phoneHeaderTitle: 'Gehirntraining Hub',
            phoneSubHeader: '8 Kategorien • 84 Denkspiele',
          ),
        2 => const ScreenData(
            badge: '⚡ 100% OFFLINE & WERBEFREI',
            title: 'ÜBERALL SPIELEN\nOHNE INTERNETVERBINDUNG',
            subtitle: 'In U-Bahn, Flugzeug und auf Reisen ohne nervige Werbung',
            accentColor: Color(0xFF10B981),
            secondaryColor: Color(0xFF059669),
            phoneHeaderTitle: 'Offline-Modus Aktiv',
            phoneSubHeader: 'Kein Datenverbrauch • Werbefrei',
          ),
        3 => const ScreenData(
            badge: '📅 PERSONALISIERTER PARCOURS',
            title: 'TÄGLICHES GEHIRNTRAINING\nFÜR MEHR VITALITÄT',
            subtitle: '3 gezielte Übungsrunden täglich für geistige Fitness',
            accentColor: Color(0xFFF59E0B),
            secondaryColor: Color(0xFFD97706),
            phoneHeaderTitle: 'Täglicher Denk-Parcours',
            phoneSubHeader: '3 Runden • Serie: 7 Tage',
          ),
        4 => const ScreenData(
            badge: '🧠 VISUELLES & ARBEITSGEDÄCHTNIS',
            title: 'GEDÄCHTNIS & FOKUS\nNACHHALTIG STÄRKEN',
            subtitle: 'Kartenpaare, Zahlenreihen und Mustererkennung',
            accentColor: Color(0xFFEC4899),
            secondaryColor: Color(0xFFDB2777),
            phoneHeaderTitle: 'Memo-Karten Arena',
            phoneSubHeader: 'Zeit: 00:42 • Combo: x3',
          ),
        5 => const ScreenData(
            badge: '♟️ TAKTIK & PROBLEMLÖSUNG',
            title: 'LOGIK, SCHACH UND\nTÜRME VON HANOI',
            subtitle: 'Meistern Sie Strategie und kritisches Denken',
            accentColor: Color(0xFF0EA5E9),
            secondaryColor: Color(0xFF0284C7),
            phoneHeaderTitle: 'Meister Türme von Hanoi',
            phoneSubHeader: 'Züge: 5 / 7 • Optimale Route',
          ),
        6 => const ScreenData(
            badge: '🔢 KOPFRECHNEN & ZAHLEN',
            title: 'ZAHLENVERSTÄNDNIS\nUND MATHE-PARCOURS',
            subtitle: '2048 Fusion, Ziel 24 und Blitz-Rechenrätsel',
            accentColor: Color(0xFF8B5CF6),
            secondaryColor: Color(0xFF6D28D9),
            phoneHeaderTitle: '2048 & Zahlenraster',
            phoneSubHeader: 'Punkte: 14.280 • Ziel: 2048',
          ),
        7 => const ScreenData(
            badge: '⚡ MILLISEKUNDEN-PRÄZISION',
            title: 'HÖCHSTE AUFMERKSAMKEIT\nUND BLITZREFLEXE',
            subtitle: 'Messen Sie Ihre Reaktionszeit auf die Millisekunde',
            accentColor: Color(0xFFEF4444),
            secondaryColor: Color(0xFFDC2626),
            phoneHeaderTitle: 'Reaktionszeit-Jagd',
            phoneSubHeader: 'Reaktion: 184 ms • Perfekt!',
          ),
        _ => const ScreenData(
            badge: '📊 KOGNITIVE AUSWERTUNG',
            title: 'ECHTER BRAIN-SCORE\nUND LEISTUNGSSTATISTIK',
            subtitle: 'Verfolgen Sie Ihre Fortschritte in 5 Schlüsselbereichen',
            accentColor: Color(0xFF14B8A6),
            secondaryColor: Color(0xFF0D9488),
            phoneHeaderTitle: 'Kognitives Leistungsprofil',
            phoneSubHeader: 'Gesamt-Score: 1480 • Meister-Level',
          ),
      };
  }
}
