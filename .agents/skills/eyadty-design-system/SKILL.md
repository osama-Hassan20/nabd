---
name: eyadty-design-system
description: Design system, color tokens, card anatomy, border radiuses, and aesthetic guidelines for Eyadty Clinic SaaS inspired by warm layered minimalism and high-radius squircle styling.
---

# Eyadty Design System — Warm Layered Minimalism Specification

## 1. Design Philosophy: "Warm Layered Minimalism"
The Eyadty UI signature is **clean, friendly, clinical yet luxurious**. It abandons harsh clinic grids, aggressive shadows, and boxy corporate styling in favor of:
- **Tone-on-Tone Depth (No Heavy Shadows):** Hierarchy is built by nesting tinted surfaces (Canvas → Soft Greige Container → Crisp White Floating Cards).
- **Generous Squircle Geometry (High Radii):** Friendly rounded corners (24px–32px cards, 100px stadium pills, 50% circular badges).
- **Color Temperature:** Warm off-white backgrounds with bold Terracotta/Coral accents (`#E0583E`) and deep Charcoal/Pitch Black (`#111111`) for crisp contrast.

---

## 2. Color Palette Tokens

### 2.1 Core Brand & Accents
```dart
class AppColors {
  // Brand Accent: Terracotta / Warm Coral
  static const Color primary = Color(0xFFE0583E); 
  static const Color primaryHover = Color(0xFFCD482F);
  static const Color primaryLight = Color(0xFFFDEEEB); // Pill washes, active tabs
  static const Color primaryMuted = Color(0xFFF8DDD7);

  // High-Contrast Accent: Pitch Black / Charcoal
  static const Color pitchBlack = Color(0xFF111111);
  static const Color darkSurface = Color(0xFF1A1A1A);

  // Surfaces & Layering (Tone-on-Tone)
  static const Color outerScaffold = Color(0xFFEBEBED); // Window background
  static const Color canvas = Color(0xFFFFFFFF);        // Main app card background
  static const Color surfaceLevel1 = Color(0xFFF6F6F8);  // Section containers / Card backplates
  static const Color surfaceLevel2 = Color(0xFFFFFFFF);  // Floating cards & action chips inside Level 1
  static const Color surfaceElevated = Color(0xFFFFFFFF);

  // Neutral Borders (Subtle & Clean)
  static const Color borderSubtle = Color(0xFFEAEAEA);
  static const Color borderLight = Color(0xFFF0F0F2);

  // Typography
  static const Color textPrimary = Color(0xFF121214);   // Deep charcoal
  static const Color textSecondary = Color(0xFF7A7A82); // Warm slate
  static const Color textMuted = Color(0xFFA6A6AE);     // Placeholders, disabled
  static const Color textInverse = Color(0xFFFFFFFF);

  // Medical Status Semantics (Soft & Harmonious)
  static const Color statusSuccess = Color(0xFF2E9A68);       // Completed / Paid
  static const Color statusSuccessLight = Color(0xFFEBF7F0);
  static const Color statusWarning = Color(0xFFE89A24);       // Waiting / In Queue
  static const Color statusWarningLight = Color(0xFFFEF6E9);
  static const Color statusError = Color(0xFFE54848);         // Cancelled / Overdue
  static const Color statusErrorLight = Color(0xFFFDF0F0);
  static const Color statusInfo = Color(0xFF3880EC);          // In Consultation
  static const Color statusInfoLight = Color(0xFFEEF4FD);
}
```

---

## 3. Radii & Shape System

```dart
class AppRadius {
  static const double shell = 32.0;       // Outer application canvas
  static const double card = 24.0;        // Major cards & section containers
  static const double innerCard = 18.0;   // Cards nested inside section containers
  static const double chip = 12.0;        // Small input tags & badges
  static const double pill = 100.0;       // Buttons, search bars, status pills (Stadium)
  static const double circle = 999.0;     // Perfect circle avatars, calendar days
}
```

---

## 4. Layering & Card Anatomy

### Rule of Tone-on-Tone Surfaces:
Never stack two identical white cards directly on top of each other. Always use the 3-level tier:

```text
Level 0: App Canvas (#FFFFFF with 32px Radius)
   │
   └── Level 1 Container (#F6F6F8 with 24px Radius & 16-24px Padding)
          │
          ├── Level 2 Floating Card (#FFFFFF with 18px Radius & Soft Tint Border)
          │      └── Level 3 Interactive Pill / Action (Pill Shape with #E0583E or #111111)
          │
          └── Level 2 Flat Section / List View
```

### Card Decoration Helper:
```dart
class AppDecorations {
  /// Major Section Backplate (Level 1)
  static BoxDecoration sectionBox({Color? color, double radius = 24}) {
    return BoxDecoration(
      color: color ?? AppColors.surfaceLevel1,
      borderRadius: BorderRadius.circular(radius),
    );
  }

  /// Floating Card (Level 2)
  static BoxDecoration cardBox({
    Color color = AppColors.surfaceLevel2,
    double radius = 18,
    bool hasBorder = true,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: hasBorder ? Border.all(color: AppColors.borderSubtle, width: 1) : null,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.015),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Pill Capsule (Buttons, Search Bars, Date Strips)
  static BoxDecoration pillBox({
    Color color = AppColors.surfaceLevel2,
    Border? border,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      border: border ?? Border.all(color: AppColors.borderSubtle, width: 1),
    );
  }
}
```

---

## 5. UI Elements Signature

### 5.1 Hero Action Buttons:
- Shape: **Full Stadium / Pill** (`BorderRadius.circular(100)`).
- Styles:
  - **Primary Action (Bold Terracotta):** Background `AppColors.primary`, white bold text, trailing circular icon arrow.
  - **Black Utility Action (Elegance):** Background `AppColors.pitchBlack`, white text.
  - **Secondary Soft Action:** Background `AppColors.surfaceLevel2` with `1px borderSubtle`.

### 5.2 Status Pills & Queue Badges:
- Full pill capsule with a **pulsing or solid status dot** on the left/right.
- Example: Light green background `#EBF7F0` + Dark green dot & text `#2E9A68` for "حضر / بالعيادة".

### 5.3 Filter Chips & Tabs:
- Horizontal strip of pill buttons resting directly inside a `#F6F6F8` container.
- Active item: Pure white `#FFFFFF` with subtle shadow or dark text.
- Inactive items: Transparent with muted text `#7A7A82`.

### 5.4 Search Fields:
- Full pill search input (`height: 48–52px`), subtle border, magnifying glass icon in a circular background.

---

## 6. Implementation Checklist for Eyadty Screens:
- [ ] Are outer cards using `radius: 24` or `28`?
- [ ] Are buttons styled as full pills (`radius: 100`)?
- [ ] Is primary action using the rich terracotta `#E0583E` or deep pitch black `#111111`?
- [ ] Is depth achieved through `#F6F6F8` tone-on-tone container backgrounds rather than heavy dropshadows?
- [ ] Are numbers and metrics clean and prominent with warm secondary labels?
