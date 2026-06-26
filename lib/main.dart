import 'package:flutter/material.dart';

import 'app.dart';
import 'services/store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppStore.instance.load();
  runApp(const GraystoneApp());
}
