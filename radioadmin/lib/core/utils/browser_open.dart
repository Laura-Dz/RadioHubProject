import 'browser_open_stub.dart'
    if (dart.library.js_interop) 'browser_open_web.dart';

void openInBrowserTab(String url) {
  openUrl(url);
}
