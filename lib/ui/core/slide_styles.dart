import 'package:film_maker/domain/models/slide.dart';
import 'package:flutter/material.dart';

TextStyle slideLayerTextStyle(
  SlideFontStyle font, {
  double fontSize = 20,
  Color color = Colors.white,
  FontWeight fontWeight = FontWeight.w600,
  List<Shadow>? shadows,
}) {
  final String family;
  final String koreanFamily;
  switch (font) {
    case SlideFontStyle.serif:
      family = 'PlayfairDisplay';
      koreanFamily = 'NotoSerifKR';
    case SlideFontStyle.sans:
      family = 'Lato';
      koreanFamily = 'NotoSansKR';
    case SlideFontStyle.script:
      family = 'DancingScript';
      koreanFamily = 'Gaegu';
    case SlideFontStyle.display:
      family = 'Cinzel';
      koreanFamily = 'BlackHanSans';
    case SlideFontStyle.elegant:
      family = 'EBGaramond';
      koreanFamily = 'GowunBatang';
    case SlideFontStyle.modern:
      family = 'Montserrat';
      koreanFamily = 'DoHyeon';
  }
  return TextStyle(
    fontFamily: family,
    fontFamilyFallback: [koreanFamily],
    fontSize: fontSize,
    color: color,
    fontWeight: fontWeight,
    shadows: shadows,
  );
}
