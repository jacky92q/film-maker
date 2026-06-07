/// Conditionally exports the platform-appropriate [downloadBytes] function.
///
/// On web it triggers a browser download; on other platforms it is a no-op
/// (native export uses the system share sheet / save dialog instead).
export 'web_download_stub.dart'
    if (dart.library.html) 'web_download_web.dart';
