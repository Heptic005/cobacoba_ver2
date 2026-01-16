import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:dakara_weighbridge/Pages/login.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future main() async {
  // Inisialisasi database
  WidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Inisialisasi ukuran layar
  appWindow.size = const Size(1280, 768);
  appWindow.alignment = Alignment.center;
  appWindow.show();

  await initializeDateFormatting('id_ID', null).then(
    (_) => runApp(
      const MaterialApp(debugShowCheckedModeBanner: false, home: LoginPage()),
    ),
  );

  doWhenWindowReady(() {
    final win = appWindow;
    const initialSize = Size(1280, 768);
    win.minSize = const Size(800, 600);
    win.size = initialSize;
    win.alignment = Alignment.center;
    win.title = "Dakara WeightBridge";
    win.show();
  });
}
