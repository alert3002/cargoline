import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand + light/dark tokens.
class CargoColors {
  static const accent = Color(0xFFFF2A42);
  static const accentBlue = Color(0xFF0072FF);
  static const glowBlue = Color(0xFF4DA3FF);
  static const success = Color(0xFF22C55E);

  static const red = accent;
  static const navy = Color(0xFF111111);

  // Dark: soft, eyes-comfortable (less red)
  static const darkBg = Color(0xFF17151A);
  static const darkCard = Color(0xCC1C1A1E);
  static const darkIconWell = Color(0x33262228);
  static const darkBorder = Color(0x22FFFFFF);
  static const darkText = Color(0xFFFFFFFF);
  static const darkMuted = Color(0xFFD0D0D0);

  // Light: soft blush, not heavy red
  static const lightBg = Color(0xFFFCFBFB);
  static const lightCard = Color(0xF2FFFFFF);
  static const lightIconWell = Color(0x12FF2A42);
  static const lightBorder = Color(0x14000000);
  static const lightText = Color(0xFF111111);
  static const lightMuted = Color(0xFF666666);

  // Legacy aliases used across app
  static const background = lightBg;
  static const card = lightCard;
  static const textPrimary = lightText;
  static const textSecondary = lightMuted;
  static const divider = Color(0xFFE5E5E5);
  static const shadow = Color(0x14000000);
  static const neonCyan = accentBlue;
  static const coffeeBg = darkBg;
  static const coffeeMid = darkCard;
  static const coffeeCard = darkCard;
  static const coffeeBorder = darkBorder;
  static const coffeeMuted = darkBorder;
  static const coffeeText = darkText;
  static const coffeeSecondary = darkMuted;

  static const brandGradient = LinearGradient(
    colors: [accentBlue, accent],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

@immutable
class CargoTheme extends ThemeExtension<CargoTheme> {
  const CargoTheme({
    required this.card,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.muted,
    required this.glow,
    required this.iconGlow,
    required this.backgroundGradient,
    required this.glass,
    required this.navBar,
    required this.inputFill,
    required this.iconWell,
  });

  final Color card;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color muted;
  final Color glow;
  final Color iconGlow;
  final Gradient backgroundGradient;
  final bool glass;
  final Color navBar;
  final Color inputFill;
  final Color iconWell;

  static CargoTheme of(BuildContext context) =>
      Theme.of(context).extension<CargoTheme>()!;

  static const light = CargoTheme(
    card: CargoColors.lightCard,
    cardBorder: CargoColors.lightBorder,
    textPrimary: CargoColors.lightText,
    textSecondary: CargoColors.lightMuted,
    muted: Color(0xFFFFE8EB),
    glow: Color(0x14000000),
    iconGlow: Colors.transparent,
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFCFBFB), Color(0xFFF7F4F5)],
    ),
    glass: false,
    navBar: Color(0xFFFFFFFF),
    inputFill: Color(0xFFFFFFFF),
    iconWell: CargoColors.lightIconWell,
  );

  static const dark = CargoTheme(
    card: CargoColors.darkCard,
    cardBorder: CargoColors.darkBorder,
    textPrimary: CargoColors.darkText,
    textSecondary: CargoColors.darkMuted,
    muted: CargoColors.darkBorder,
    glow: Color(0x22FF2A42),
    iconGlow: Color(0x33FF2A42),
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF17151A), Color(0xFF151318), Color(0xFF131216)],
    ),
    glass: false,
    navBar: Color(0xFF161218),
    inputFill: Color(0xFF1E1A1F),
    iconWell: CargoColors.darkIconWell,
  );

  @override
  CargoTheme copyWith({
    Color? card,
    Color? cardBorder,
    Color? textPrimary,
    Color? textSecondary,
    Color? muted,
    Color? glow,
    Color? iconGlow,
    Gradient? backgroundGradient,
    bool? glass,
    Color? navBar,
    Color? inputFill,
    Color? iconWell,
  }) {
    return CargoTheme(
      card: card ?? this.card,
      cardBorder: cardBorder ?? this.cardBorder,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      muted: muted ?? this.muted,
      glow: glow ?? this.glow,
      iconGlow: iconGlow ?? this.iconGlow,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      glass: glass ?? this.glass,
      navBar: navBar ?? this.navBar,
      inputFill: inputFill ?? this.inputFill,
      iconWell: iconWell ?? this.iconWell,
    );
  }

  @override
  CargoTheme lerp(ThemeExtension<CargoTheme>? other, double t) {
    if (other is! CargoTheme) return this;
    return t < 0.5 ? this : other;
  }
}

class ParcelAppTheme {
  static TextTheme _textTheme(Color primary, Color secondary, Color titles) {
    return GoogleFonts.plusJakartaSansTextTheme().copyWith(
      displayLarge: GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: titles,
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: titles,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: titles,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: primary,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: secondary,
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }

  static ThemeData get lightTheme {
    const cargo = CargoTheme.light;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: const ColorScheme.light(
        primary: CargoColors.accent,
        secondary: CargoColors.accentBlue,
        surface: CargoColors.lightCard,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: CargoColors.lightText,
      ),
      extensions: const [cargo],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: CargoColors.lightText,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: CargoColors.lightText,
        ),
      ),
      textTheme: _textTheme(
        cargo.textPrimary,
        cargo.textSecondary,
        CargoColors.lightText,
      ),
      filledButtonTheme: _filledButton(),
      outlinedButtonTheme: _outlined(CargoColors.lightText, CargoColors.lightBorder),
      inputDecorationTheme: _inputs(cargo, dark: false),
      snackBarTheme: _snackBars(),
      pageTransitionsTheme: _transitions,
      dividerColor: cargo.muted,
      iconTheme: const IconThemeData(color: CargoColors.lightText),
    );
  }

  static ThemeData get darkTheme {
    const cargo = CargoTheme.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: const ColorScheme.dark(
        primary: CargoColors.accent,
        secondary: CargoColors.accentBlue,
        surface: CargoColors.darkCard,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: CargoColors.darkText,
      ),
      extensions: const [cargo],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: CargoColors.darkText,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: CargoColors.darkText,
        ),
      ),
      // Titles slightly red-tinted white mix for dark mode
      textTheme: _textTheme(
        cargo.textPrimary,
        cargo.textSecondary,
        const Color(0xFFFFE8EB), // white ~70% + red tint ~30%
      ),
      filledButtonTheme: _filledButton(),
      outlinedButtonTheme: _outlined(CargoColors.darkText, CargoColors.darkBorder),
      inputDecorationTheme: _inputs(cargo, dark: true),
      snackBarTheme: _snackBars(),
      pageTransitionsTheme: _transitions,
      dividerColor: cargo.muted,
      iconTheme: const IconThemeData(color: CargoColors.darkText),
    );
  }

  static FilledButtonThemeData _filledButton() => FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: CargoColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  static OutlinedButtonThemeData _outlined(Color fg, Color border) =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: fg,
          side: BorderSide(color: border, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );

  static InputDecorationTheme _inputs(CargoTheme cargo, {required bool dark}) =>
      InputDecorationTheme(
        filled: true,
        fillColor: cargo.inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cargo.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: dark ? CargoColors.darkBorder : CargoColors.lightBorder,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: CargoColors.accent, width: 1.4),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: cargo.textSecondary,
          fontSize: 14,
        ),
      );

  static SnackBarThemeData _snackBars() => SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: CargoColors.darkCard,
        contentTextStyle: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );

  static const _transitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    },
  );
}

class CargoBackground extends StatelessWidget {
  const CargoBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cargo = CargoTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(gradient: cargo.backgroundGradient),
      child: child,
    );
  }
}

/// Profile sub-screens: red iOS-style back control.
AppBar cargoProfileAppBar(BuildContext context, Widget title) {
  return AppBar(
    leading: IconButton(
      icon: const Icon(
        Icons.arrow_back_ios_new_rounded,
        size: 20,
        color: CargoColors.red,
      ),
      onPressed: () => Navigator.of(context).maybePop(),
    ),
    title: title,
  );
}

class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(16);

    final content = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // iOS-like glass: translucent fill, no colored stroke
        color: isDark
            ? const Color(0x991E1A1F)
            : const Color(0xCCFFFFFF),
        borderRadius: radius,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.55),
          width: 0.6,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
            blurRadius: isDark ? 12 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        splashColor: CargoColors.accent.withValues(alpha: 0.08),
        child: content,
      ),
    );
  }
}

class AppTheme {
  static final ThemeData darkTheme = ParcelAppTheme.darkTheme.copyWith(
    primaryColor: CargoColors.accent,
    scaffoldBackgroundColor: CargoColors.darkBg,
  );

  static final ThemeData lightTheme = ParcelAppTheme.lightTheme.copyWith(
    primaryColor: CargoColors.accent,
    scaffoldBackgroundColor: CargoColors.lightBg,
  );
}
