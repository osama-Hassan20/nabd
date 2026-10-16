import 'dart:ui';

class AppColors {
  // ─── Brand Colors (Purexo - Muted & Executive Palette) ─────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF1E477A); // أزرق محيطي هادئ ومريح للعين
  static const Color primaryDark = Color(
    0xFF132F52,
  ); // كحلي عميق للنصوص والعناوين
  static const Color primaryLight = Color(
    0xFFEDF4FC,
  ); // خلفية زرقاء ناعمة جداً للعناصر النشطة
  static const Color secondary = Color(0xFF2A724A); // أخضر طبيعي هادئ ومتزن
  static const Color secondaryLight = Color(
    0xFFEBF5EF,
  ); // خلفية خضراء باهتة لحالات النجاح

  // ─── Grays & Neutrals ──────────────────────────────────────────────────────
  static const Color gray = Color(0xFF64748B);
  static const Color grayf6 = Color(0xFFF8FAFC);
  static const Color grayf2 = Color(0xFFF1F5F9);
  static const Color grayf4 = Color(0xFFF1F5F9);
  static const Color gray71717A = Color(0xFF71717A);
  static const Color gray7A828E = Color(0xFF64748B);
  static const Color gray6C6C6C = Color(0xFF64748B);
  static const Color gray334155 = Color(0xFF334155);
  static const Color grayE2E8F0 = Color(0xFFE2E8F0);
  static const Color grayMuted = Color(0xFF94A3B8);
  static const Color grayDim = Color(0xFF64748B);
  static const Color grayAccent = Color(0xFF8F96AD);
  static const Color grayBorder = Color(0xFFE2E8F0);
  static const Color grayMid = Color(0xFF64748B);
  static const Color grayVeryLight = Color(0xFFF1F5F9);
  static const Color grayLight217 = Color(0xFFE2E8F0);
  static const Color grayBlue = Color(0xFF94A3B8);

  // ─── Surfaces & Backgrounds ────────────────────────────────────────────────
  static const Color lightBackground = Color(
    0xFFF8FAFC,
  ); // خلفية رئيسية ناعمة بدون إجهاد بصري
  static const Color darkBackground = Color(0xFF0F172A); // خلفية داكنة فخمة
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightGray = Color(0xFFF8FAFC);
  static const Color lightGrayAlt = Color(0xFFE2E8F0);
  static const Color lightGrayF2 = Color(0xFFF1F5F9);
  static const Color lightGrayF5 = Color(0xFFF8FAFC);
  static const Color lightGrayF2F5 = Color(0xFFF1F5F9);
  static const Color lightWarm = Color(0xFFF8FAFC);
  static const Color fillDisableColor = Color(
    0xFFF1F5F9,
  ); // حقول الإدخال والأزرار الثانوية

  // ─── Inputs & Borders ──────────────────────────────────────────────────────
  static const Color inputColor = Color(0xFF1E293B);
  static const Color inputBorderColor = Color(0xFFE2E8F0);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFE2E8F0);

  // ─── Typography ────────────────────────────────────────────────────────────
  static const Color darkText = Color(0xFF0F172A);
  static const Color darkText2 = Color(0xFF1E293B);
  static const Color darkCharcoal = Color(0xFF1E293B);
  static const Color veryDark = Color(0xFF0F172A);
  static const Color almostBlack = Color(0xFF0F172A);
  static const Color darkGray = Color(0xFF475569);
  static const Color darkGray33 = Color(0xFF1E293B);
  static const Color darkSlate = Color(0xFF334155);
  static const Color mediumGray = Color(0xFF475569);
  static const Color mediumGrayAlt = Color(0xFF64748B);
  static const Color black = Color(0xFF000000);

  // ─── Accent & Status Colors ────────────────────────────────────────────────
  static const Color accent = Color(
    0xFF4A7C9F,
  ); // ستيل بلو هادئ بدلاً من الأصفر
  static const Color success = Color(0xFF2A724A); // أخضر شجري متزن
  static const Color error = Color(0xFFDC2626); // أحمر غير فاقع
  static const Color warning = Color(0xFFD97706); // عنبري متزن
  static const Color orange = Color(0xFFD97706);
  static const Color amber = Color(0xFFD97706);
  static const Color yellowF4CA01 = Color(0xFFD97706);
  static const Color yellowFFAA00 = Color(0xFFD97706);
  static const Color yellowLight = Color(0xFFFEF3C7);
  static const Color yellowPale = Color(0xFFFFFBEB);

  // ─── Green Variants ────────────────────────────────────────────────────────
  static const Color darkGreen = Color(0xFF1E5637);
  static const Color darkGreenAlt = Color(0xFF153F28);
  static const Color lightGreen = Color(0xFF439366);
  static const Color greenMuted = Color(0xFF3B7A57);
  static const Color green95B8B3 = Color(0xFF7FA89E);
  static const Color lightGreenEFF8F0 = Color(0xFFEBF5EF);
  static const Color lightGreen96C97C = Color(0xFF4A8860);
  static const Color lightGreen35BEAA = Color(0xFF347D68);
  static const Color green3FB864 = Color(0xFF2A724A);
  static const Color green9CD39E29 = Color.fromRGBO(42, 114, 74, 0.12);
  static const Color lightGreenAccent = Color(0xFFD4EAD9);

  // ─── Blue Variants ─────────────────────────────────────────────────────────
  static const Color blue = Color(0xFF1E477A);
  static const Color darkNavy = Color(0xFF0A192F);
  static const Color darkBlue = Color(0xFF132F52);
  static const Color lightBlue = Color(0xFFD6E6F5);
  static const Color veryLightBlue = Color(0xFFEDF4FC);
  static const Color paleLightBlue = Color(0xFFF4F8FD);
  static const Color cyan = Color(0xFF4A7C9F);
  static const Color tealGray = Color(0xFF6B8A99);

  // ─── Red Variants ──────────────────────────────────────────────────────────
  static const Color red = Color(0xFFDC2626);
  static const Color red02 = Color(0xFFDC2626);
  static const Color red1A = Color.fromRGBO(220, 38, 38, 0.1);
  static const Color pink = Color(0xFFBE185D);
  static const Color taupe = Color(0xFF94A3B8);
}
