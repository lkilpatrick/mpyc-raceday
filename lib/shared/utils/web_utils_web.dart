// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;

void openHtmlInNewTab(String htmlContent, String title) {
  final blob = html.Blob([htmlContent], 'text/html');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, title);
}

void downloadCsvWeb(String csvContent, String filename) {
  final bytes = utf8.encode(csvContent);
  final blob = html.Blob([bytes], 'text/csv');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}

Object createIFrameElement({
  required String src,
  String width = '100%',
  String height = '100%',
}) {
  return html.IFrameElement()
    ..src = src
    ..style.border = 'none'
    ..style.width = width
    ..style.height = height;
}

void registerPlatformViewFactory(String viewType, Object Function(int viewId) factory) {
  ui_web.platformViewRegistry.registerViewFactory(viewType, factory);
}
