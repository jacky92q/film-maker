// Conditionally exports the platform-appropriate downloadBytes function.
// On web it triggers a browser download; on other platforms it is a no-op.
export 'web_download_stub.dart'
    if (dart.library.html) 'web_download_web.dart';
