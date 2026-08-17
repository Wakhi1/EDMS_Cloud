import 'package:flutter/material.dart';

/// Raw design tokens from the PSPF EDMS design mockup
/// (edms-prototype-flutter/project/PSPF EDMS Prototype.dc.html, lines 15-30).
///
/// Exposed as a [ThemeExtension] because several of these (ink2/ink3,
/// line/line2, surf2/surf3, sel, bar/barInk/barLine) have no equivalent slot
/// in Flutter's [ColorScheme] and the mockup distinguishes them precisely.
@immutable
class PspfTokens extends ThemeExtension<PspfTokens> {
  const PspfTokens({
    required this.paper,
    required this.surf,
    required this.surf2,
    required this.surf3,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.line,
    required this.line2,
    required this.acc,
    required this.accD,
    required this.accT,
    required this.acc2,
    required this.bar,
    required this.barInk,
    required this.barLine,
    required this.ok,
    required this.warn,
    required this.bad,
    required this.info,
    required this.sel,
  });

  final Color paper;
  final Color surf;
  final Color surf2;
  final Color surf3;
  final Color ink;
  final Color ink2;
  final Color ink3;
  final Color line;
  final Color line2;
  final Color acc;
  final Color accD;
  final Color accT;
  final Color acc2;
  final Color bar;
  final Color barInk;
  final Color barLine;
  final Color ok;
  final Color warn;
  final Color bad;
  final Color info;
  final Color sel;

  static const light = PspfTokens(
    paper: Color(0xFFF3F2F2),
    surf: Color(0xFFFFFFFF),
    surf2: Color(0xFFE9E7E6),
    surf3: Color(0xFFDEDBD9),
    ink: Color(0xFF201E1D),
    ink2: Color(0xFF5D5854),
    ink3: Color(0xFF8A8481),
    line: Color(0xFFC9C5C2),
    line2: Color(0xFFB3AEAA),
    acc: Color(0xFF0088B0),
    accD: Color(0xFF006B8C),
    accT: Color(0xFFDCEEF4),
    acc2: Color(0xFFD6006C),
    bar: Color(0xFF201E1D),
    barInk: Color(0xFFF3F2F2),
    barLine: Color(0xFF0088B0),
    ok: Color(0xFF1C6B3A),
    warn: Color(0xFF8A5A00),
    bad: Color(0xFFA3231B),
    info: Color(0xFF0088B0),
    sel: Color(0xFFDCEEF4),
  );

  static const dark = PspfTokens(
    paper: Color(0xFF17191A),
    surf: Color(0xFF1F2223),
    surf2: Color(0xFF282C2D),
    surf3: Color(0xFF33383A),
    ink: Color(0xFFE8E6E4),
    ink2: Color(0xFFA9A5A1),
    ink3: Color(0xFF7D7975),
    line: Color(0xFF3A3F41),
    line2: Color(0xFF4B5153),
    acc: Color(0xFF4CB8D8),
    accD: Color(0xFF7CD0E8),
    accT: Color(0xFF12333D),
    acc2: Color(0xFFFF5FA2),
    bar: Color(0xFF101213),
    barInk: Color(0xFFE8E6E4),
    barLine: Color(0xFF4CB8D8),
    ok: Color(0xFF5CC286),
    warn: Color(0xFFE0A640),
    bad: Color(0xFFF2756B),
    info: Color(0xFF4CB8D8),
    sel: Color(0xFF12333D),
  );

  @override
  PspfTokens copyWith({
    Color? paper,
    Color? surf,
    Color? surf2,
    Color? surf3,
    Color? ink,
    Color? ink2,
    Color? ink3,
    Color? line,
    Color? line2,
    Color? acc,
    Color? accD,
    Color? accT,
    Color? acc2,
    Color? bar,
    Color? barInk,
    Color? barLine,
    Color? ok,
    Color? warn,
    Color? bad,
    Color? info,
    Color? sel,
  }) {
    return PspfTokens(
      paper: paper ?? this.paper,
      surf: surf ?? this.surf,
      surf2: surf2 ?? this.surf2,
      surf3: surf3 ?? this.surf3,
      ink: ink ?? this.ink,
      ink2: ink2 ?? this.ink2,
      ink3: ink3 ?? this.ink3,
      line: line ?? this.line,
      line2: line2 ?? this.line2,
      acc: acc ?? this.acc,
      accD: accD ?? this.accD,
      accT: accT ?? this.accT,
      acc2: acc2 ?? this.acc2,
      bar: bar ?? this.bar,
      barInk: barInk ?? this.barInk,
      barLine: barLine ?? this.barLine,
      ok: ok ?? this.ok,
      warn: warn ?? this.warn,
      bad: bad ?? this.bad,
      info: info ?? this.info,
      sel: sel ?? this.sel,
    );
  }

  @override
  PspfTokens lerp(ThemeExtension<PspfTokens>? other, double t) {
    if (other is! PspfTokens) return this;
    return PspfTokens(
      paper: Color.lerp(paper, other.paper, t)!,
      surf: Color.lerp(surf, other.surf, t)!,
      surf2: Color.lerp(surf2, other.surf2, t)!,
      surf3: Color.lerp(surf3, other.surf3, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      ink2: Color.lerp(ink2, other.ink2, t)!,
      ink3: Color.lerp(ink3, other.ink3, t)!,
      line: Color.lerp(line, other.line, t)!,
      line2: Color.lerp(line2, other.line2, t)!,
      acc: Color.lerp(acc, other.acc, t)!,
      accD: Color.lerp(accD, other.accD, t)!,
      accT: Color.lerp(accT, other.accT, t)!,
      acc2: Color.lerp(acc2, other.acc2, t)!,
      bar: Color.lerp(bar, other.bar, t)!,
      barInk: Color.lerp(barInk, other.barInk, t)!,
      barLine: Color.lerp(barLine, other.barLine, t)!,
      ok: Color.lerp(ok, other.ok, t)!,
      warn: Color.lerp(warn, other.warn, t)!,
      bad: Color.lerp(bad, other.bad, t)!,
      info: Color.lerp(info, other.info, t)!,
      sel: Color.lerp(sel, other.sel, t)!,
    );
  }
}

/// Fetch the active [PspfTokens] from a [BuildContext] — shorthand for
/// `Theme.of(context).extension<PspfTokens>()!`.
extension PspfTokensContext on BuildContext {
  PspfTokens get tokens => Theme.of(this).extension<PspfTokens>()!;
}
