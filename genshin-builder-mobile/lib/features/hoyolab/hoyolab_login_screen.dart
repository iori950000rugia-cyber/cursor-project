import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../data/hoyolab/hoyolab_constants.dart';
import 'widgets/hoyolab_disclaimer_banner.dart';

class HoyolabLoginScreen extends StatefulWidget {
  const HoyolabLoginScreen({super.key});

  @override
  State<HoyolabLoginScreen> createState() => _HoyolabLoginScreenState();
}

class _HoyolabLoginScreenState extends State<HoyolabLoginScreen> {
  late final WebViewController _controller;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => setState(() => _loading = false),
        ),
      )
      ..loadRequest(Uri.parse(HoyolabConstants.loginUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HoYoLAB ログイン'),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: HoyolabDisclaimerBanner(compact: true),
          ),
          Expanded(
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_loading)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'HoYoLAB にログイン後、「連携を完了」を押してください。',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(true),
                    icon: const Icon(Icons.check),
                    label: const Text('連携を完了'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
