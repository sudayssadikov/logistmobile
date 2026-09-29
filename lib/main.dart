import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/app.dart';
import 'core/di/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style for seamless edge-to-edge SaaS design
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF090A0F),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize dependency injection (Services, Repositories, Blocs)
  await configureDependencies();

  runApp(const LogiFlowApp());
}
