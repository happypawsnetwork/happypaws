import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../utils/app_logger.dart';

class SecureTokenService {
  final FlutterSecureStorage _secureStorage;
  final _log = AppLogger('SecureTokenService');

  String? _cachedAccessToken;

  SecureTokenService({FlutterSecureStorage? storage})
    : _secureStorage =
          storage ?? const FlutterSecureStorage(aOptions: AndroidOptions());

  static const String _accessTokenKey = 'hp_access_token';
  static const String _refreshTokenKey = 'hp_refresh_token';

  Future<String?> getAccessToken() async {
    if (_cachedAccessToken != null) {
      _log.trace('Returning cached access token');
      return _cachedAccessToken;
    }

    _log.trace('Reading access token from secure storage');
    _cachedAccessToken = await _secureStorage.read(key: _accessTokenKey);
    return _cachedAccessToken;
  }

  Future<String?> getRefreshToken() async {
    _log.trace('Reading refresh token from secure storage');
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _log.info('Saving new tokens to secure storage');
    _cachedAccessToken = accessToken;

    await Future.wait([
      _secureStorage.write(key: _accessTokenKey, value: accessToken),
      _secureStorage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
  }

  Future<void> clearTokens() async {
    _log.info('Clearing tokens from secure storage');
    _cachedAccessToken = null;
    await Future.wait([
      _secureStorage.delete(key: _accessTokenKey),
      _secureStorage.delete(key: _refreshTokenKey),
    ]);
  }
}
