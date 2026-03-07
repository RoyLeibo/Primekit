import 'package:flutter/material.dart';

/// Border radius constants.
abstract class PkRadius {
  PkRadius._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double full = 999.0;

  static BorderRadius circle = BorderRadius.circular(full);
  static BorderRadius card = BorderRadius.circular(md);
  static BorderRadius button = BorderRadius.circular(sm);
  static BorderRadius chip = BorderRadius.circular(lg);
}
