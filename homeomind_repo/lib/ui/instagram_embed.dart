import 'package:flutter/material.dart'; // This was missing and caused your build failure
import 'dart:ui_web' as ui_web;
import 'dart:html' as html;

class InstagramEmbed extends StatelessWidget {
  const InstagramEmbed({super.key});

  static const _viewType = 'instagram-embed';
  static bool _registered = false;

  void _register() {
    if (_registered) return;
    _registered = true;
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final iframe = html.IFrameElement()
        ..src = 'https://www.instagram.com/muhammadibrahimubharay/embed/'
        ..style.border = 'none'
        ..style.borderRadius = '12px'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allowFullscreen = true;
      return iframe;
    });
  }

  @override
  Widget build(BuildContext context) {
    _register();
    return const SizedBox(
      height: 420,
      child: HtmlElementView(viewType: _viewType),
    );
  }
}
