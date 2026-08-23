import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter/services.dart';

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  InAppWebViewController? controller;
  PullToRefreshController? pullToRefreshController;

  double progress = 0;

  @override
  void initState() {
    super.initState();

    pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(
        color: Colors.blue,
      ),
      onRefresh: () async {
        await controller?.reload();
      },
    );
  }
Future<void> downloadFile(String url) async {

  try {

    final directory = await getApplicationDocumentsDirectory();

    final fileName = url.split('/').last.split('?').first;

    final filePath = "${directory.path}/$fileName";


    await Dio().download(
      url,
      filePath,
    );


    await OpenFilex.open(filePath);


  } catch (e) {

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("حدث خطأ أثناء تحميل الملف: $e"),
        ),
      );
    }

  }

}
  @override
  Widget build(BuildContext context) {
return PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, result) async {
    if (didPop) return;

    final canGoBack = await controller?.canGoBack() ?? false;

    if (canGoBack) {
      await controller?.goBack();
    } else {
      // لا توجد صفحات سابقة داخل الموقع
      // Android: إغلاق التطبيق
      SystemNavigator.pop();
    }
  },
      child: Scaffold(
        body: Column(
          children: [
            if (progress < 1.0)
              LinearProgressIndicator(value: progress),
            Expanded(
child: InAppWebView(
  pullToRefreshController: pullToRefreshController,

  initialUrlRequest: URLRequest(
    url: WebUri("http://94.156.189.207/index.php"),
  ),

  initialSettings: InAppWebViewSettings(
    allowsBackForwardNavigationGestures: true,
    javaScriptEnabled: true,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    allowFileAccess: true,
    allowContentAccess: true,
    useHybridComposition: true,
    supportZoom: false,
    sharedCookiesEnabled: true,
    thirdPartyCookiesEnabled: true,
    domStorageEnabled: true,
    databaseEnabled: true,
    javaScriptCanOpenWindowsAutomatically: true,
  ),

  onWebViewCreated: (webController) {
    controller = webController;
  },

  shouldOverrideUrlLoading: (controller, navigationAction) async {
    final uri = navigationAction.request.url;

    if (uri == null) {
      return NavigationActionPolicy.ALLOW;
    }

    // معالجة روابط intent:// الخاصة بجوجل ماب
    if (uri.scheme == "intent") {
      final intentUrl = uri.toString();

      final fallbackUrl = RegExp(
        r'S.browser_fallback_url=([^;]+)',
      ).firstMatch(intentUrl)?.group(1);

      if (fallbackUrl != null) {
        final decodedUrl = Uri.decodeComponent(fallbackUrl);

        await launchUrl(
          Uri.parse(decodedUrl),
          mode: LaunchMode.externalApplication,
        );
      }

      return NavigationActionPolicy.CANCEL;
    }

    // فتح Google Maps خارج الـ WebView
    if (uri.host.contains("google.com") ||
        uri.host.contains("maps.google.com")) {
      
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      return NavigationActionPolicy.CANCEL;
    }

    return NavigationActionPolicy.ALLOW;
  },

  onProgressChanged: (webController, p) {
    setState(() {
      progress = p / 100;
    });

    if (p == 100) {
      pullToRefreshController?.endRefreshing();
    }
  },

  onLoadStop: (controller, url) async {
    pullToRefreshController?.endRefreshing();
  },

  onDownloadStartRequest: (controller, request) async {
    final uri = Uri.parse(request.url.toString());

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
                  );
                 }
               },
              ),
            ),
          ],
        ),
      ),
    );
  }
}