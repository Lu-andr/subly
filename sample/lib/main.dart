import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:subly/subly.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  debugPaintBaselinesEnabled = false;
  debugPaintSizeEnabled = false;
  debugPaintPointersEnabled = false;
  runApp(const SublyApp());
}
