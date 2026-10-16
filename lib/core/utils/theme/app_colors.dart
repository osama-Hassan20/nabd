import 'dart:ui';

class AppColors {
  // ─── Brand Colors (Eyadty - Warm Terracotta & Obsidian Palette) ───────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFFE0583E); // تيراكوتا دافئ ومركزي كبطل للتصميم
  static const Color primaryHover = Color(0xFFCD482F);
  static const Color primaryDark = Color(0xFF111111); // أسود فحمي فاخر للنصوص والأزرار
  static const Color primaryLight = Color(0xFFFDEEEB); // خلفية خوخية ناعمة جداً للعناصر النشطة
  static const Color primaryMuted = Color(0xFFF8DDD7);
  static const Color pitchBlack = Color(0xFF111111);
  static const Color darkPrimary = Color(0xFF111111);
  static const Color darkSurface = Color(0xFF18181A);

  static const Color secondary = Color(0xFF2D6A4F); // أوكالبتوس غابي أنيق ينسجم بتناغم مكمل مع التيراكوتا
  static const Color secondaryLight = Color(0xFFEEF6F2); // غسول أوكالبتوس ناعم جداً لحالات الاكتمال والتأكيد
  static const Color secondaryDark = Color(0xFF1E4A37);
  static const Color secondaryHover = Color(0xFF245741);

  // ─── Tone-on-Tone Surfaces & Layering ───────────────────────────────────────
  static const Color outerScaffold = Color(0xFFEBEBED); // خلفية النافذة الخارجية
  static const Color canvas = Color(0xFFFFFFFF); // الإطار الأساسي
  static const Color surfaceLevel1 = Color(0xFFF6F6F8); // حاويات الأقسام والكاردات الكبيرة
  static const Color surfaceLevel2 = Color(0xFFFFFFFF); // كاردات داخلية عائمة ناصعة البياض
  static const Color lightBackground = Color(0xFFF6F6F8); // خلفية رئيسية ناعمة ومريحة
  static const Color darkBackground = Color(0xFF121214); // خلفية داكنة فخمة
  static const Color lightBg = Color(0xFFF6F6F8);
  static const Color lightGray = Color(0xFFF6F6F8);
  static const Color lightGrayAlt = Color(0xFFEAEAEA);
  static const Color lightGrayF2 = Color(0xFFF6F6F8);
  static const Color lightGrayF5 = Color(0xFFF6F6F8);
  static const Color lightGrayF2F5 = Color(0xFFF6F6F8);
  static const Color lightWarm = Color(0xFFFDFBF9);
  static const Color fillDisableColor = Color(0xFFF0F0F2);

  // ─── Borders & Dividers ───────────────────────────────────────────────────
  static const Color borderSubtle = Color(0xFFEAEAEA); // بوردر خفيف وناعم جداً
  static const Color borderLight = Color(0xFFF0F0F2);
  static const Color inputBorderColor = Color(0xFFEAEAEA);
  static const Color lightBorder = Color(0xFFEAEAEA);
  static const Color grayBorder = Color(0xFFEAEAEA);

  // ─── Grays & Neutrals ──────────────────────────────────────────────────────
  static const Color gray = Color(0xFF7A7A82); // رمادي دافئ متزن للنصوص الثانوية
  static const Color grayf6 = Color(0xFFF6F6F8);
  static const Color grayf2 = Color(0xFFF6F6F8);
  static const Color grayf4 = Color(0xFFF6F6F8);
  static const Color gray71717A = Color(0xFF71717A);
  static const Color gray7A828E = Color(0xFF7A7A82);
  static const Color gray6C6C6C = Color(0xFF7A7A82);
  static const Color gray334155 = Color(0xFF333336);
  static const Color grayE2E8F0 = Color(0xFFEAEAEA);
  static const Color grayMuted = Color(0xFFA6A6AE);
  static const Color grayDim = Color(0xFF7A7A82);
  static const Color grayAccent = Color(0xFF8F8F96);
  static const Color grayMid = Color(0xFF7A7A82);
  static const Color grayVeryLight = Color(0xFFF6F6F8);
  static const Color grayLight217 = Color(0xFFEAEAEA);
  static const Color grayBlue = Color(0xFF8E8E93);

  // ─── Typography ────────────────────────────────────────────────────────────
  static const Color darkText = Color(0xFF121214); // نصوص رئيسية كحلية/فحمية شديدة الوضوح
  static const Color darkText2 = Color(0xFF222226);
  static const Color darkCharcoal = Color(0xFF1E1E22);
  static const Color veryDark = Color(0xFF121214);
  static const Color almostBlack = Color(0xFF111111);
  static const Color darkGray = Color(0xFF4A4A52);
  static const Color darkGray33 = Color(0xFF2E2E33);
  static const Color darkSlate = Color(0xFF38383E);
  static const Color mediumGray = Color(0xFF6E6E76);
  static const Color mediumGrayAlt = Color(0xFF7A7A82);
  static const Color black = Color(0xFF111111);

  // ─── Inputs ────────────────────────────────────────────────────────────────
  static const Color inputColor = Color(0xFF121214);

  // ─── Accent & Status Colors ────────────────────────────────────────────────
  static const Color accent = Color(0xFFE0583E); // تيراكوتا كعلامة رئيسية
  static const Color success = Color(0xFF2E9A68); // أخضر طبي هادئ
  static const Color error = Color(0xFFE54848); // أحمر واضح وغير فاقع
  static const Color warning = Color(0xFFE89A24); // برتقالي دافئ للانتظار
  static const Color orange = Color(0xFFE89A24);
  static const Color amber = Color(0xFFE89A24);
  static const Color yellowF4CA01 = Color(0xFFE89A24);
  static const Color yellowFFAA00 = Color(0xFFE89A24);
  static const Color yellowLight = Color(0xFFFEF6E9);
  static const Color yellowPale = Color(0xFFFFF9F0);

  // ─── Green Variants ────────────────────────────────────────────────────────
  static const Color darkGreen = Color(0xFF247A53);
  static const Color darkGreenAlt = Color(0xFF1D6343);
  static const Color lightGreen = Color(0xFF48B37C);
  static const Color greenMuted = Color(0xFF3E8E68);
  static const Color green95B8B3 = Color(0xFF7FA89E);
  static const Color lightGreenEFF8F0 = Color(0xFFEBF7F0);
  static const Color lightGreen96C97C = Color(0xFF55A67C);
  static const Color lightGreen35BEAA = Color(0xFF3EA38C);
  static const Color green3FB864 = Color(0xFF2E9A68);
  static const Color green9CD39E29 = Color.fromRGBO(46, 154, 104, 0.12);
  static const Color lightGreenAccent = Color(0xFFD6F0E0);

  // ─── Blue / Cyan Variants ──────────────────────────────────────────────────
  static const Color blue = Color(0xFF3880EC);
  static const Color darkNavy = Color(0xFF111111);
  static const Color darkBlue = Color(0xFF1A1A1A);
  static const Color lightBlue = Color(0xFFEEF4FD);
  static const Color veryLightBlue = Color(0xFFF3F7FE);
  static const Color paleLightBlue = Color(0xFFF8FAFF);
  static const Color cyan = Color(0xFF2B9EA8);
  static const Color tealGray = Color(0xFF6B8A99);

  // ─── Red Variants ──────────────────────────────────────────────────────────
  static const Color red = Color(0xFFE54848);
  static const Color red02 = Color(0xFFE54848);
  static const Color red1A = Color.fromRGBO(229, 72, 72, 0.1);
  static const Color pink = Color(0xFFD94876);
  static const Color taupe = Color(0xFF8E8E93);
}
