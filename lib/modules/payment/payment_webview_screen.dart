import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import '../../core/localization/strings/payment_strings.dart';
import '../../core/network/api_exception.dart';
import '../../core/services/payment_api_service.dart';
import '../../core/theme/app_colors.dart';

/// Opens a bank's online payment page ([ApiEndpoints.paymentOrders]'s
/// `invoiceUrl`) inside the app. Closing early (the X button) pops `false`.
///
/// One specific redirect *is* watched for — the bank's own post-payment
/// `return_url` lands on `.../payments/activate-order/:id?orderId=...`,
/// which is what actually credits the top-up ([PaymentApiService.
/// activateOrder]); that URL is caught and handled instead of letting the
/// WebView load it (its raw JSON response, and the backend serves it under
/// a path the bank's redirect gets slightly wrong — see that method). Any
/// other host/path change is left alone: the invoice host (mpi.gov.tm)
/// legitimately redirects through other domains mid-flow for 3D-Secure, so
/// a broader "left the invoice's domain" rule would risk closing this on
/// the OTP step rather than on an actual finish.
class PaymentWebViewScreen extends StatefulWidget {
  final String url;
  const PaymentWebViewScreen({super.key, required this.url});

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..enableZoom(true)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          if (mounted) setState(() => _loading = true);
        },
        onPageFinished: (_) {
          if (mounted) setState(() => _loading = false);
          // The bank's own pages (mpi.gov.tm, acs.gov.tm, ...) don't all
          // ship a `width=device-width` viewport tag, so the WebView falls
          // back to rendering at a desktop-ish width and the user has to
          // pinch-zoom out to see the card form at all. Forcing one after
          // every page load fixes that regardless of which of the bank's
          // pages this is currently on.
          _controller.runJavaScript(_forceResponsiveViewportJs);
        },
        // Logged unconditionally (not just the activate-order match) —
        // temporary, until a real card payment confirms this actually
        // fires for the bank's post-payment redirect the way `mpi.gov.tm`
        // is expected to make it.
        onNavigationRequest: (request) async {
          log('💳 webview navigation: ${request.url}');
          final uri = Uri.tryParse(request.url);
          if (uri == null || !uri.path.contains('/payments/activate-order/')) {
            return NavigationDecision.navigate;
          }
          log('💳 activate-order match — calling PaymentApiService.activateOrder');
          try {
            await PaymentApiService.activateOrder(uri);
            log('💳 activate-order call finished with no error');
          } on ApiException catch (e) {
            // Best-effort — whatever happens, closing this and letting the
            // caller's post-close balance refresh reveal the real outcome
            // beats leaving the user stuck on a page that was never going
            // to render (it's a JSON response, not a webpage). Logged
            // rather than truly silent, since this is exactly the kind of
            // failure that otherwise looks identical to "nothing happened".
            log('💳 activate-order call failed: ${e.message} (status ${e.statusCode})');
          }
          if (mounted) Navigator.of(context).pop(true);
          return NavigationDecision.prevent;
        },
      ))
      ..loadRequest(Uri.parse(widget.url));

    // `AndroidWebViewController` defaults `useWideViewPort` to false —
    // unlike plain `android.webkit.WebView`, whose own default is also
    // false but is normally flipped on by whoever configures the WebView,
    // which this plugin's controller never does on its own. With it off,
    // the WebView ignores any viewport meta tag entirely (including the
    // one forced in `onPageFinished` below) and lays the page out at a
    // fixed desktop-ish width, which is what made every bank page open
    // pre-zoomed-in until the user manually pinched out. iOS's WKWebView
    // has no equivalent setting — it already respects viewport tags.
    final platform = _controller.platform;
    if (platform is AndroidWebViewController) platform.setUseWideViewPort(true);
  }

  // Sets (or creates, if the page never shipped one) the viewport meta tag
  // to a standard mobile one, so the bank's own desktop-oriented layout
  // renders at the WebView's actual width instead of a zoomed-out desktop-
  // sized page. Pinch-zoom is left on (no `user-scalable=no`/
  // `maximum-scale`) — some of these pages have small print the user still
  // needs to be able to zoom into by hand.
  static const _forceResponsiveViewportJs = '''
    (function() {
      var meta = document.querySelector('meta[name="viewport"]');
      if (!meta) {
        meta = document.createElement('meta');
        meta.name = 'viewport';
        document.getElementsByTagName('head')[0].appendChild(meta);
      }
      meta.content = 'width=device-width, initial-scale=1.0';
    })();
  ''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(PaymentStrings.paymentPageTitle, style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading) LinearProgressIndicator(color: AppColors.primary, backgroundColor: Colors.transparent),
        ],
      ),
    );
  }
}
