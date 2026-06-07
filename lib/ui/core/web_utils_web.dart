import 'package:web/web.dart' as web;

String? getCurrentDomain() {
  final host = web.window.location.hostname;
  return host.isEmpty ? null : host;
}
