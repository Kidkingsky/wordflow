import 'package:flutter/material.dart';

/// WordFlow Editorial Learning tokens — kept separate from learning logic.
abstract final class WordFlowDesign {
  static const paper = Color(0xFFF6F3EE);
  static const card = Color(0xFFFFFEFC);
  static const ink = Color(0xFF292535);
  static const inkSoft = Color(0xFF433A4C);
  static const muted = Color(0xFF716976);
  static const rule = Color(0xFFE3DDD7);
  static const plum = Color(0xFF624D79);
  static const plumDeep = Color(0xFF483659);
  static const plumWash = Color(0xFFEEE7F2);
  static const sage = Color(0xFFE1E8DB);
  static const sageDeep = Color(0xFF496951);
  static const rose = Color(0xFFF1E1D7);

  static TextStyle english({double size = 34, Color color = ink}) =>
      TextStyle(
        fontFamily: 'Georgia',
        fontFamilyFallback: const ['Noto Serif', 'serif'],
        fontSize: size,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.8,
        height: 1.18,
        color: color,
      );

  static TextStyle title({double size = 26}) => TextStyle(
    fontSize: size,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.3,
    color: ink,
  );

  static const label = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w600, color: muted,
  );
  static const body = TextStyle(
    fontSize: 15, height: 1.5, color: inkSoft,
  );

  static BoxDecoration panel({Color color = card, double radius = 18}) =>
      BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: rule),
      );

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: plum, brightness: Brightness.light,
      surface: card, primary: plum,
    ).copyWith(onSurface: ink, onPrimary: Colors.white, secondary: sageDeep);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: paper,
      textTheme: ThemeData.light().textTheme.apply(bodyColor: ink, displayColor: ink),
      appBarTheme: const AppBarTheme(
        backgroundColor: paper, foregroundColor: ink,
        elevation: 0, centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: card,
        elevation: 0,
        indicatorColor: plumWash,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
          color: states.contains(WidgetState.selected) ? plum : muted,
          fontSize: 11, fontWeight: FontWeight.w600,
        )),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
          size: 22,
          color: states.contains(WidgetState.selected) ? plum : muted,
        )),
      ),
      dividerColor: rule,
      cardTheme: CardThemeData(
        color: card, elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: rule),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        prefixIconColor: muted,
        hintStyle: const TextStyle(color: muted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: rule),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: rule),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: plum, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: card,
        selectedColor: plumWash,
        side: const BorderSide(color: rule),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        labelStyle: const TextStyle(color: ink, fontWeight: FontWeight.w600),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: plum,
          foregroundColor: Colors.white,
          minimumSize: const Size(44, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: plum,
          side: const BorderSide(color: rule),
          minimumSize: const Size(44, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: plum),
      ),
    );
  }
}

class WordFlowWordmark extends StatelessWidget {
  const WordFlowWordmark({super.key});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 30, height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: WordFlowDesign.plum,
          borderRadius: BorderRadius.circular(9),
        ),
        child: const Text('w.', style: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 18, color: Colors.white,
          fontWeight: FontWeight.w600,
        )),
      ),
      const SizedBox(width: 9),
      Text('WordFlow', style: WordFlowDesign.english(size: 23)),
    ],
  );
}

class WordFlowSectionTitle extends StatelessWidget {
  const WordFlowSectionTitle({required this.text, this.trailing, super.key});
  final String text;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Text(text, style: WordFlowDesign.title(size: 20))),
    if (trailing != null) trailing!,
  ]);
}
