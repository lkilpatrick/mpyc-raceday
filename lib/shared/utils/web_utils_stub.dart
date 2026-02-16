// Stub implementations for non-web platforms.

void openHtmlInNewTab(String htmlContent, String title) {
  // No-op on non-web platforms
}

void downloadCsvWeb(String csvContent, String filename) {
  // No-op on non-web platforms
}

Object createIFrameElement({
  required String src,
  String width = '100%',
  String height = '100%',
}) {
  // No-op on non-web platforms
  throw UnsupportedError('IFrame is only supported on web');
}

void registerPlatformViewFactory(String viewType, Object Function(int viewId) factory) {
  // No-op on non-web platforms
}
