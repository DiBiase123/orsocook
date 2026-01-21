import 'package:flutter/material.dart';

class DetailConstants {
  // Dimensioni e spaziature
  static const double imageHeight = 200.0;
  static const double borderRadius = 12.0;
  static const double chipBorderRadius = 16.0;

  // Padding
  static const EdgeInsets defaultPadding = EdgeInsets.all(16.0);
  static const EdgeInsets sectionPadding = EdgeInsets.only(bottom: 20.0);
  static const EdgeInsets cardPadding = EdgeInsets.all(12.0);

  // Margini
  static const EdgeInsets imageMargin = EdgeInsets.only(bottom: 16, top: 8);
  static const EdgeInsets chipMargin = EdgeInsets.only(bottom: 8);

  // Spaziature
  static const double smallSpacing = 4.0;
  static const double mediumSpacing = 8.0;
  static const double largeSpacing = 12.0;
  static const double xlargeSpacing = 16.0;
  static const double xxlargeSpacing = 20.0;
  static const double sectionSpacing = 24.0;
  static const double extraSectionSpacing = 40.0;

  // Dimensioni icone
  static const double smallIconSize = 16.0;
  static const double mediumIconSize = 24.0;
  static const double largeIconSize = 50.0;

  // Dimensioni testo
  static const double titleFontSize = 24.0;
  static const double subtitleFontSize = 20.0;
  static const double bodyFontSize = 16.0;
  static const double captionFontSize = 14.0;

  // Colori
  static const Color primaryColor = Colors.orange;
  static const Color shadowColor = Color.fromRGBO(0, 0, 0, 0.1);
  static const Color greyColor = Colors.grey;
  static const Color lightGreyColor = Color(0xFFF5F5F5);
  static const Color chipBackground = Color(0xFFFFF3E0); // orange[50]
  static const Color chipBorder = Color(0xFFFFB74D); // orange[300]
  static const Color chipText = Color(0xFFE65100); // orange[900]

  // Shadow
  static const BoxShadow defaultShadow = BoxShadow(
    color: shadowColor,
    blurRadius: 6,
    offset: Offset(0, 3),
  );

  // Stili di testo
  static const TextStyle titleStyle = TextStyle(
    fontSize: titleFontSize,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontSize: subtitleFontSize,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: bodyFontSize,
  );

  static const TextStyle captionStyle = TextStyle(
    fontSize: captionFontSize,
    color: greyColor,
  );

  static const TextStyle boldCaptionStyle = TextStyle(
    fontSize: bodyFontSize,
    fontWeight: FontWeight.bold,
  );

  // Tempo di cache per le immagini
  static const Duration imageCacheDuration = Duration(minutes: 10);

  // Dimensione cache immagini (performance)
  static const int imageCacheWidth = 800;
  static const int imageCacheHeight = 600;
}
