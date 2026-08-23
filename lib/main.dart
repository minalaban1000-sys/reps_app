import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'webview_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
  );

  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WebViewPage(),
    ),
  );
}