import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class KaliTypography {
  final TextStyle displayBase;
  final TextStyle headingBase;
  final TextStyle headingItalicBase;
  final TextStyle bodyBase;
  final TextStyle labelBase;
  final TextStyle captionBase;
  final TextStyle loginDisplayBase;
  final TextStyle loginBodyBase;

  const KaliTypography({
    required this.displayBase,
    required this.headingBase,
    required this.headingItalicBase,
    required this.bodyBase,
    required this.labelBase,
    required this.captionBase,
    required this.loginDisplayBase,
    required this.loginBodyBase,
  });

  // ─── Helpers ──────────────────────────────────────────────────────────────

  TextStyle display(Color color, {double size = 36}) =>
      displayBase.copyWith(color: color, fontSize: size);

  TextStyle heading(Color color, {double size = 24}) =>
      headingBase.copyWith(color: color, fontSize: size);

  TextStyle headingItalic(Color color, {double size = 26}) =>
      headingItalicBase.copyWith(color: color, fontSize: size);

  TextStyle body(Color color,
          {double size = 13, FontWeight weight = FontWeight.w400}) =>
      bodyBase.copyWith(color: color, fontSize: size, fontWeight: weight);

  TextStyle label(Color color) => labelBase.copyWith(color: color);

  TextStyle caption(Color color) => captionBase.copyWith(color: color);

  TextStyle loginDisplay(Color color) =>
      loginDisplayBase.copyWith(color: color);

  TextStyle loginBody(Color color) => loginBodyBase.copyWith(color: color);

  // ─── Variantes predefinidas ───────────────────────────────────────────────

  static final KaliTypography defaultTypography = KaliTypography(
    displayBase: GoogleFonts.cormorantGaramond(
        fontSize: 36, fontWeight: FontWeight.w300, fontStyle: FontStyle.italic),
    headingBase: GoogleFonts.cormorantGaramond(
        fontSize: 24, fontWeight: FontWeight.w300),
    headingItalicBase: GoogleFonts.cormorantGaramond(
        fontSize: 26, fontWeight: FontWeight.w300, fontStyle: FontStyle.italic),
    bodyBase: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w400),
    labelBase: GoogleFonts.dmSans(
        fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 1.4),
    captionBase: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w300),
    loginDisplayBase:
        GoogleFonts.newsreader(fontSize: 36, fontWeight: FontWeight.bold),
    loginBodyBase:
        GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.normal),
  );

  static final KaliTypography darkTypography = KaliTypography(
    displayBase: GoogleFonts.outfit(
        fontSize: 36, fontWeight: FontWeight.w300, fontStyle: FontStyle.italic),
    headingBase: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w300),
    headingItalicBase: GoogleFonts.outfit(
        fontSize: 26, fontWeight: FontWeight.w300, fontStyle: FontStyle.italic),
    bodyBase: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400),
    labelBase: GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 1.4),
    captionBase: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w300),
    loginDisplayBase:
        GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.bold),
    loginBodyBase:
        GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.normal),
  );

  static final KaliTypography oceanTypography = KaliTypography(
    displayBase: GoogleFonts.quicksand(
        fontSize: 36, fontWeight: FontWeight.w400, fontStyle: FontStyle.italic),
    headingBase:
        GoogleFonts.quicksand(fontSize: 24, fontWeight: FontWeight.w400),
    headingItalicBase: GoogleFonts.quicksand(
        fontSize: 26, fontWeight: FontWeight.w400, fontStyle: FontStyle.italic),
    bodyBase: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w400),
    labelBase: GoogleFonts.nunito(
        fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1.2),
    captionBase: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w400),
    loginDisplayBase:
        GoogleFonts.quicksand(fontSize: 36, fontWeight: FontWeight.bold),
    loginBodyBase:
        GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.normal),
  );

  static final KaliTypography natureTypography = KaliTypography(
    displayBase: GoogleFonts.lora(
        fontSize: 36, fontWeight: FontWeight.w400, fontStyle: FontStyle.italic),
    headingBase:
        GoogleFonts.lora(fontSize: 24, fontWeight: FontWeight.w400),
    headingItalicBase: GoogleFonts.lora(
        fontSize: 26, fontWeight: FontWeight.w400, fontStyle: FontStyle.italic),
    bodyBase: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w400),
    labelBase: GoogleFonts.workSans(
        fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 1.2),
    captionBase: GoogleFonts.workSans(fontSize: 11, fontWeight: FontWeight.w400),
    loginDisplayBase:
        GoogleFonts.lora(fontSize: 36, fontWeight: FontWeight.bold),
    loginBodyBase:
        GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.normal),
  );

  static final KaliTypography magentaTypography = KaliTypography(
    displayBase: GoogleFonts.playfairDisplay(
        fontSize: 36, fontWeight: FontWeight.w400, fontStyle: FontStyle.italic),
    headingBase:
        GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w400),
    headingItalicBase: GoogleFonts.playfairDisplay(
        fontSize: 26, fontWeight: FontWeight.w400, fontStyle: FontStyle.italic),
    bodyBase: GoogleFonts.lato(fontSize: 13, fontWeight: FontWeight.w400),
    labelBase: GoogleFonts.lato(
        fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1.2),
    captionBase: GoogleFonts.lato(fontSize: 11, fontWeight: FontWeight.w400),
    loginDisplayBase:
        GoogleFonts.playfairDisplay(fontSize: 36, fontWeight: FontWeight.bold),
    loginBodyBase:
        GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.normal),
  );

  KaliTypography lerp(KaliTypography? other, double t) {
    if (other == null) return this;
    return KaliTypography(
      displayBase: TextStyle.lerp(displayBase, other.displayBase, t)!,
      headingBase: TextStyle.lerp(headingBase, other.headingBase, t)!,
      headingItalicBase:
          TextStyle.lerp(headingItalicBase, other.headingItalicBase, t)!,
      bodyBase: TextStyle.lerp(bodyBase, other.bodyBase, t)!,
      labelBase: TextStyle.lerp(labelBase, other.labelBase, t)!,
      captionBase: TextStyle.lerp(captionBase, other.captionBase, t)!,
      loginDisplayBase:
          TextStyle.lerp(loginDisplayBase, other.loginDisplayBase, t)!,
      loginBodyBase: TextStyle.lerp(loginBodyBase, other.loginBodyBase, t)!,
    );
  }
}
