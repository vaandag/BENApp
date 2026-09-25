import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MapLibreMap.useHybridComposition = true;
  runApp(const BENApp());
}
