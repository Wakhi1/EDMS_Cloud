import 'package:flutter/material.dart';

/// Parses a "#RRGGBB" string into a [Color], or null if it isn't one —
/// shared by anything that reads a company branding color (theme
/// building, the logo letter-avatar fallback).
Color? parseHexColor(String? hex) {
  if (hex == null || !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(hex)) return null;
  return Color(int.parse('FF${hex.substring(1)}', radix: 16));
}
