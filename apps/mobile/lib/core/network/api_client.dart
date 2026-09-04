// ignore_for_file: prefer_initializing_formals

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/env_config.dart';
import '../storage/secure_token_service.dart';
import '../utils/app_logger.dart';
import 'api_exceptions.dart';

class ApiClient {
  final http.Client _client;
  final SecureTokenService _tokenService;
  final _log = AppLogger('ApiClient');

  bool _isRefreshing = false;
  Future<void>? _refreshFuture;

  ApiClient({http.Client? client, required SecureTokenService tokenService})
    : _client = client ?? http.Client(),
      _tokenService = tokenService;

  Future<Map<String, String>> _getHeaders() async {
    final headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.acceptHeader: 'application/json',
    };

    final token = await _tokenService.getAccessToken();
    if (token != null) {
      headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
    }
    return headers;
  }

  void _handleError(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;

    String? problemTitle;
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body.containsKey('title')) {
        problemTitle = body['title'];
      }
    } catch (_) {}

    if (response.statusCode == 429) {
      throw RateLimitException(
        problemTitle ?? 'Too many failed attempts. Try again later.',
      );
    } else if (response.statusCode == 401) {
      throw UnauthorizedException();
    } else if (response.statusCode == 403) {
      throw ForbiddenException();
    } else if (response.statusCode == 409) {
      throw ConflictException(
        problemTitle ?? 'Resource already exists or conflict occurred.',
      );
    } else {
      throw ApiException(
        problemTitle ??
            'An error occurred (StatusCode: ${response.statusCode})',
        statusCode: response.statusCode,
      );
    }
  }

  Future<bool> _refreshToken() async {
    if (_isRefreshing) {
      try {
        await _refreshFuture;
        return true;
      } catch (_) {
        return false;
      }
    }

    _isRefreshing = true;
    _refreshFuture = _performRefresh();
    try {
      await _refreshFuture;
      return true;
    } catch (e) {
      return false;
    } finally {
      _isRefreshing = false;
      _refreshFuture = null;
    }
  }

  Future<void> _performRefresh() async {
    final refreshToken = await _tokenService.getRefreshToken();
    if (refreshToken == null) {
      _log.warning('No refresh token found in storage.');
      throw UnauthorizedException();
    }

    _log.info('Attempting to refresh access token...');
    final uri = Uri.parse('${EnvConfig.apiBaseUrl}/api/auth/refresh');
    final response = await _client.post(
      uri,
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.acceptHeader: 'application/json',
      },
      body: jsonEncode({'refreshToken': refreshToken}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = jsonDecode(response.body);
      await _tokenService.saveTokens(
        accessToken: body['accessToken'],
        refreshToken: body['refreshToken'],
      );
      _log.info('Token refreshed successfully.');
    } else {
      _log.warning(
        'Token refresh failed (StatusCode: ${response.statusCode}). Clearing tokens.',
      );
      await _tokenService.clearTokens();
      throw UnauthorizedException();
    }
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    bool isRetry = false,
  }) async {
    try {
      final uri = Uri.parse('${EnvConfig.apiBaseUrl}$path');
      _log.info('POST $uri');
      if (body != null) {
        _log.debug('Request body: $body');
      }

      final response = await _client.post(
        uri,
        headers: await _getHeaders(),
        body: body != null ? jsonEncode(body) : null,
      );

      _log.info('Response status: ${response.statusCode} (POST $uri)');
      _handleError(response);

      return response.body.isEmpty ? null : jsonDecode(response.body);
    } on UnauthorizedException {
      if (isRetry ||
          path.contains('/api/auth/refresh') ||
          path.contains('/api/auth/mobile/login') ||
          path.contains('/api/auth/revoke')) {
        rethrow;
      }

      _log.info(
        'Caught 401 Unauthorized on POST $path. Initiating token refresh...',
      );
      final refreshed = await _refreshToken();
      if (refreshed) {
        _log.info('Retrying POST $path after successful refresh.');
        return post(path, body: body, isRetry: true);
      } else {
        rethrow;
      }
    } on SocketException catch (e, st) {
      _log.error('Network exception during POST $path', e, st);
      throw NetworkException();
    } catch (e, st) {
      if (e is! UnauthorizedException) {
        _log.error('Error during POST $path', e, st);
      }
      rethrow;
    }
  }

  Future<dynamic> put(
    String path, {
    Map<String, dynamic>? body,
    bool isRetry = false,
  }) async {
    try {
      final uri = Uri.parse('${EnvConfig.apiBaseUrl}$path');
      _log.info('PUT $uri');
      if (body != null) {
        _log.debug('Request body: $body');
      }

      final response = await _client.put(
        uri,
        headers: await _getHeaders(),
        body: body != null ? jsonEncode(body) : null,
      );

      _log.info('Response status: ${response.statusCode} (PUT $uri)');
      _handleError(response);

      return response.body.isEmpty ? null : jsonDecode(response.body);
    } on UnauthorizedException {
      if (isRetry || path.contains('/api/auth/refresh')) {
        rethrow;
      }

      _log.info(
        'Caught 401 Unauthorized on PUT $path. Initiating token refresh...',
      );
      final refreshed = await _refreshToken();
      if (refreshed) {
        _log.info('Retrying PUT $path after successful refresh.');
        return put(path, body: body, isRetry: true);
      } else {
        rethrow;
      }
    } on SocketException catch (e, st) {
      _log.error('Network exception during PUT $path', e, st);
      throw NetworkException();
    } catch (e, st) {
      if (e is! UnauthorizedException) {
        _log.error('Error during PUT $path', e, st);
      }
      rethrow;
    }
  }

  Future<dynamic> patch(
    String path, {
    Map<String, dynamic>? body,
    bool isRetry = false,
  }) async {
    try {
      final uri = Uri.parse('${EnvConfig.apiBaseUrl}$path');
      _log.info('PATCH $uri');
      if (body != null) {
        _log.debug('Request body: $body');
      }

      final response = await _client.patch(
        uri,
        headers: await _getHeaders(),
        body: body != null ? jsonEncode(body) : null,
      );

      _log.info('Response status: ${response.statusCode} (PATCH $uri)');
      _handleError(response);

      return response.body.isEmpty ? null : jsonDecode(response.body);
    } on UnauthorizedException {
      if (isRetry || path.contains('/api/auth/refresh')) {
        rethrow;
      }

      _log.info(
        'Caught 401 Unauthorized on PATCH $path. Initiating token refresh...',
      );
      final refreshed = await _refreshToken();
      if (refreshed) {
        _log.info('Retrying PATCH $path after successful refresh.');
        return patch(path, body: body, isRetry: true);
      } else {
        rethrow;
      }
    } on SocketException catch (e, st) {
      _log.error('Network exception during PATCH $path', e, st);
      throw NetworkException();
    } catch (e, st) {
      if (e is! UnauthorizedException) {
        _log.error('Error during PATCH $path', e, st);
      }
      rethrow;
    }
  }

  Future<dynamic> get(String path, {bool isRetry = false}) async {
    try {
      final uri = Uri.parse('${EnvConfig.apiBaseUrl}$path');
      _log.info('GET $uri');

      final response = await _client.get(uri, headers: await _getHeaders());

      _log.info('Response status: ${response.statusCode} (GET $uri)');
      _handleError(response);

      return response.body.isEmpty ? null : jsonDecode(response.body);
    } on UnauthorizedException {
      if (isRetry || path.contains('/api/auth/refresh')) {
        rethrow;
      }

      _log.info(
        'Caught 401 Unauthorized on GET $path. Initiating token refresh...',
      );
      final refreshed = await _refreshToken();
      if (refreshed) {
        _log.info('Retrying GET $path after successful refresh.');
        return get(path, isRetry: true);
      } else {
        rethrow;
      }
    } on SocketException catch (e, st) {
      _log.error('Network exception during GET $path', e, st);
      throw NetworkException();
    } catch (e, st) {
      if (e is! UnauthorizedException) {
        _log.error('Error during GET $path', e, st);
      }
      rethrow;
    }
  }

  Future<dynamic> multipart(
    String path, {
    required List<File> files,
    String fieldName = 'file',
    bool isRetry = false,
  }) async {
    try {
      final uri = Uri.parse('${EnvConfig.apiBaseUrl}$path');
      _log.info('MULTIPART $uri');

      var request = http.MultipartRequest('POST', uri);
      final headers = await _getHeaders();
      // Remove content-type so http creates its own multipart boundary
      headers.remove(HttpHeaders.contentTypeHeader);
      request.headers.addAll(headers);

      for (var file in files) {
        final ext = file.path.split('.').last.toLowerCase();
        MediaType? mediaType;
        if (ext == 'png') {
          mediaType = MediaType('image', 'png');
        } else if (ext == 'webp') {
          mediaType = MediaType('image', 'webp');
        } else if (ext == 'gif') {
          mediaType = MediaType('image', 'gif');
        } else {
          mediaType = MediaType('image', 'jpeg');
        }

        var multipartFile = await http.MultipartFile.fromPath(
          fieldName,
          file.path,
          contentType: mediaType,
        );
        request.files.add(multipartFile);
      }

      var streamedResponse = await _client.send(request);
      var response = await http.Response.fromStream(streamedResponse);

      _log.info('Response status: ${response.statusCode} (MULTIPART $uri)');
      _handleError(response);

      return response.body.isEmpty ? null : jsonDecode(response.body);
    } on UnauthorizedException {
      if (isRetry || path.contains('/api/auth/refresh')) rethrow;
      final refreshed = await _refreshToken();
      if (refreshed) {
        return multipart(
          path,
          files: files,
          fieldName: fieldName,
          isRetry: true,
        );
      } else {
        rethrow;
      }
    } on SocketException catch (e, st) {
      _log.error('Network exception during MULTIPART $path', e, st);
      throw NetworkException();
    } catch (e, st) {
      if (e is! UnauthorizedException) {
        _log.error('Error during MULTIPART $path', e, st);
      }
      rethrow;
    }
  }

  Future<dynamic> delete(String path, {bool isRetry = false}) async {
    try {
      final uri = Uri.parse('${EnvConfig.apiBaseUrl}$path');
      _log.info('DELETE $uri');

      final response = await _client.delete(uri, headers: await _getHeaders());

      _log.info('Response status: ${response.statusCode} (DELETE $uri)');
      _handleError(response);

      return response.body.isEmpty ? null : jsonDecode(response.body);
    } on UnauthorizedException {
      if (isRetry || path.contains('/api/auth/refresh')) rethrow;
      final refreshed = await _refreshToken();
      if (refreshed) {
        return delete(path, isRetry: true);
      } else {
        rethrow;
      }
    } on SocketException catch (e, st) {
      _log.error('Network exception during DELETE $path', e, st);
      throw NetworkException();
    } catch (e, st) {
      if (e is! UnauthorizedException) {
        _log.error('Error during DELETE $path', e, st);
      }
      rethrow;
    }
  }
}
