import '../config/env_config.dart';

class UrlHelper {
  /// Resolves URLs returned from the API for local development.
  /// Replaces 'localhost' or '127.0.0.1' with the host from [EnvConfig.apiBaseUrl]
  /// such as '10.0.2.2' for Android emulator or LAN IP for physical devices.
  static String? resolveUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) return rawUrl;
    try {
      final uri = Uri.parse(rawUrl);
      final apiUri = Uri.parse(EnvConfig.apiBaseUrl);
      if ((uri.host == 'localhost' || uri.host == '127.0.0.1') &&
          apiUri.host.isNotEmpty &&
          apiUri.host != 'localhost' &&
          apiUri.host != '127.0.0.1') {
        return uri.replace(host: apiUri.host).toString();
      }
    } catch (_) {}
    return rawUrl;
  }
}
