import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:signalr_netcore/signalr_client.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/storage/secure_token_service.dart';
import '../../data/models/chat_thread.dart';
import '../../data/models/message.dart';

class ChatController extends ChangeNotifier {
  final SecureTokenService _storage = SecureTokenService();
  HubConnection? _hubConnection;

  List<ChatThread> _threads = [];
  List<ChatThread> get threads => _threads;

  List<Message> _currentMessages = [];
  List<Message> get currentMessages => _currentMessages;

  int? _activeThreadId;
  int? get activeThreadId => _activeThreadId;

  int? _activeTargetUserId;
  int? get activeTargetUserId => _activeTargetUserId;

  bool _iBlocked = false;
  bool get iBlocked => _iBlocked;

  bool _theyBlocked = false;
  bool get theyBlocked => _theyBlocked;

  bool get isBlocked => _iBlocked || _theyBlocked;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int get totalUnreadCount =>
      _threads.fold<int>(0, (sum, t) => sum + (t.isSelf ? 0 : t.unreadCount));

  Timer? _pollingTimer;

  Future<void> initialize() async {
    await fetchThreads();
    await _initSignalR();
  }

  Future<void> _initSignalR() async {
    if (_hubConnection?.state == HubConnectionState.Connected ||
        _hubConnection?.state == HubConnectionState.Connecting) {
      return;
    }

    final token = await _storage.getAccessToken();
    if (token == null) return;

    final baseUri = Uri.parse('${EnvConfig.apiBaseUrl}/chatHub');
    final hubUrl = baseUri
        .replace(queryParameters: {'access_token': token})
        .toString();

    _hubConnection = HubConnectionBuilder()
        .withUrl(
          hubUrl,
          options: HttpConnectionOptions(
            accessTokenFactory: () async =>
                (await _storage.getAccessToken()) ?? '',
            requestTimeout: 10000,
          ),
        )
        .withAutomaticReconnect()
        .build();

    _hubConnection?.on('ReceiveMessage', _handleReceiveMessage);
    _hubConnection?.on('MessageSeen', _handleMessageSeen);
    _hubConnection?.on('UserBlockStatusChanged', _handleBlockStatusChanged);

    _hubConnection?.onclose(({error}) {
      debugPrint('[SignalR] Hub connection closed: $error');
    });

    _hubConnection?.onreconnecting(({error}) {
      debugPrint('[SignalR] Hub reconnecting: $error');
    });

    _hubConnection?.onreconnected(({connectionId}) {
      debugPrint('[SignalR] Hub reconnected: $connectionId');
      fetchThreads();
      if (_activeThreadId != null) {
        _pollMessagesSilently(_activeThreadId!);
      }
    });

    try {
      debugPrint('[SignalR] Starting connection to $hubUrl');
      await _hubConnection?.start();
      debugPrint(
        '[SignalR] Connection established. State: ${_hubConnection?.state}',
      );
    } catch (e) {
      debugPrint('[SignalR] Connection failed: $e');
    }
  }

  void _handleReceiveMessage(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    try {
      final rawMap = args[0] as Map;
      final msgData = Map<String, dynamic>.from(rawMap);
      final message = Message.fromJson(msgData);

      if (message.threadId == _activeThreadId) {
        if (!_currentMessages.any((m) => m.id == message.id)) {
          _currentMessages.add(message);
          _markAsSeen(message.id);
          notifyListeners();
        }
      }

      _updateThreadListWithNewMessage(message);
    } catch (e) {
      debugPrint('Error handling received message: $e');
    }
  }

  void _handleMessageSeen(List<Object?>? args) {
    if (args == null || args.length < 2) return;
    final messageId = args[0] as int;
    final seenAt = args[1] as String;

    final index = _currentMessages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      final old = _currentMessages[index];
      _currentMessages[index] = Message(
        id: old.id,
        senderId: old.senderId,
        messageType: old.messageType,
        content: old.content,
        latitude: old.latitude,
        longitude: old.longitude,
        sentAt: old.sentAt,
        deliveredAt: old.deliveredAt,
        seenAt: DateTime.parse(seenAt),
        threadId: old.threadId,
      );
      notifyListeners();
    }
  }

  void _handleBlockStatusChanged(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    try {
      final rawMap = args[0] as Map;
      final data = Map<String, dynamic>.from(rawMap);
      final targetUserId =
          data['targetUserId'] as int? ?? data['TargetUserId'] as int?;
      if (targetUserId == _activeTargetUserId) {
        _iBlocked = (data['iBlocked'] ?? data['IBlocked']) == true;
        _theyBlocked = (data['theyBlocked'] ?? data['TheyBlocked']) == true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error handling UserBlockStatusChanged: $e');
    }
  }

  void _updateThreadListWithNewMessage(Message message) {
    final threadIndex = _threads.indexWhere((t) => t.id == message.threadId);
    if (threadIndex != -1) {
      final old = _threads[threadIndex];
      final isSelfThread = old.isSelf;
      _threads[threadIndex] = ChatThread(
        id: old.id,
        isDirectMessage: old.isDirectMessage,
        isSelf: old.isSelf,
        updatedAt: message.sentAt,
        otherParticipant: old.otherParticipant,
        lastMessage: message,
        unreadCount: (message.threadId == _activeThreadId || isSelfThread)
            ? 0
            : old.unreadCount + 1,
      );
      _threads.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      notifyListeners();
    } else {
      fetchThreads();
    }
  }

  Future<void> _markAsSeen(int messageId) async {
    if (_hubConnection?.state == HubConnectionState.Connected) {
      await _hubConnection?.invoke(
        'MarkMessageAsSeen',
        args: <Object>[messageId],
      );
    }
  }

  Future<void> fetchThreads() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _storage.getAccessToken();
      final response = await http.get(
        Uri.parse('${EnvConfig.apiBaseUrl}/api/messaging/threads'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        _threads = data.map((e) => ChatThread.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching threads: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearActiveThread() {
    _activeThreadId = null;
    _activeTargetUserId = null;
    _iBlocked = false;
    _theyBlocked = false;
    _stopPolling();
    notifyListeners();
  }

  void _startPolling(int threadId) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_activeThreadId == threadId) {
        _pollMessagesSilently(threadId);
      }
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _pollMessagesSilently(int threadId) async {
    try {
      final token = await _storage.getAccessToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse(
          '${EnvConfig.apiBaseUrl}/api/messaging/threads/$threadId/messages',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200 && _activeThreadId == threadId) {
        final List data = json.decode(response.body);
        final fetched = data.map((e) => Message.fromJson(e)).toList();

        bool hasChanges = false;
        if (fetched.length != _currentMessages.length) {
          hasChanges = true;
        } else {
          for (int i = 0; i < fetched.length; i++) {
            if (fetched[i].id != _currentMessages[i].id ||
                fetched[i].seenAt != _currentMessages[i].seenAt ||
                fetched[i].deliveredAt != _currentMessages[i].deliveredAt) {
              hasChanges = true;
              break;
            }
          }
        }

        if (hasChanges && _activeThreadId == threadId) {
          _currentMessages = fetched;
          for (final msg in _currentMessages.where((m) => m.seenAt == null)) {
            _markAsSeen(msg.id);
          }
          notifyListeners();
        }
      }
    } catch (_) {
      // Silently ignore background polling errors
    }
  }

  Future<void> loadMessages(int threadId) async {
    _activeThreadId = threadId;
    _currentMessages = [];
    _isLoading = true;
    _startPolling(threadId);

    final threadIndex = _threads.indexWhere((t) => t.id == threadId);
    if (threadIndex != -1 && _threads[threadIndex].unreadCount > 0) {
      final t = _threads[threadIndex];
      _threads[threadIndex] = ChatThread(
        id: t.id,
        isDirectMessage: t.isDirectMessage,
        isSelf: t.isSelf,
        updatedAt: t.updatedAt,
        otherParticipant: t.otherParticipant,
        lastMessage: t.lastMessage,
        unreadCount: 0,
      );
    }
    notifyListeners();

    try {
      final token = await _storage.getAccessToken();
      final response = await http.get(
        Uri.parse(
          '${EnvConfig.apiBaseUrl}/api/messaging/threads/$threadId/messages',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        _currentMessages = data.map((e) => Message.fromJson(e)).toList();

        for (final msg in _currentMessages.where((m) => m.seenAt == null)) {
          _markAsSeen(msg.id);
        }
      }
    } catch (e) {
      debugPrint('Error loading messages: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(
    int targetUserId,
    String content, {
    double? lat,
    double? lng,
  }) async {
    final msgType = lat != null && lng != null ? 'Location' : 'Text';

    if (_hubConnection?.state == HubConnectionState.Connected) {
      try {
        await _hubConnection?.invoke(
          'SendDirectMessage',
          args: <Object>[
            targetUserId,
            content,
            msgType,
            lat ?? 0.0,
            lng ?? 0.0,
          ],
        );
        return;
      } catch (e) {
        debugPrint('SignalR SendDirectMessage error: $e');
      }
    }

    // HTTP fallback when SignalR is unavailable
    try {
      final token = await _storage.getAccessToken();
      final response = await http.post(
        Uri.parse(
          '${EnvConfig.apiBaseUrl}/api/messaging/threads/direct/$targetUserId/messages',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'content': content,
          'messageType': msgType,
          'latitude': lat,
          'longitude': lng,
        }),
      );

      if (response.statusCode == 200) {
        final msgData = json.decode(response.body) as Map<String, dynamic>;
        final sent = Message.fromJson(msgData);
        if (sent.threadId == _activeThreadId) {
          _currentMessages.add(sent);
          notifyListeners();
        }
        _updateThreadListWithNewMessage(sent);
      }
    } catch (e) {
      debugPrint('HTTP send message error: $e');
    }
  }

  Future<int?> findOrCreateThread(int targetUserId) async {
    try {
      final token = await _storage.getAccessToken();
      final response = await http.post(
        Uri.parse(
          '${EnvConfig.apiBaseUrl}/api/messaging/threads/direct/$targetUserId',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final threadId = data['threadId'] as int;

        if (!_threads.any((t) => t.id == threadId)) {
          await fetchThreads();
        }

        return threadId;
      }
    } catch (_) {}
    return null;
  }

  Future<void> checkBlockStatus(int targetUserId) async {
    _activeTargetUserId = targetUserId;
    try {
      final token = await _storage.getAccessToken();
      final response = await http.get(
        Uri.parse(
          '${EnvConfig.apiBaseUrl}/api/messaging/can-message/$targetUserId',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _iBlocked = data['iBlocked'] == true || data['IBlocked'] == true;
        _theyBlocked =
            data['theyBlocked'] == true || data['TheyBlocked'] == true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error checking block status: $e');
    }
  }

  Future<bool> blockUser(int userId) async {
    try {
      final token = await _storage.getAccessToken();
      final response = await http.post(
        Uri.parse('${EnvConfig.apiBaseUrl}/api/messaging/block/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        _iBlocked = true;
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> unblockUser(int userId) async {
    try {
      final token = await _storage.getAccessToken();
      final response = await http.post(
        Uri.parse('${EnvConfig.apiBaseUrl}/api/messaging/unblock/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        _iBlocked = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> canMessageUser(int userId) async {
    try {
      final token = await _storage.getAccessToken();
      final response = await http.get(
        Uri.parse('${EnvConfig.apiBaseUrl}/api/messaging/can-message/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['canMessage'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteThread(int threadId) async {
    try {
      final token = await _storage.getAccessToken();
      final response = await http.delete(
        Uri.parse('${EnvConfig.apiBaseUrl}/api/messaging/threads/$threadId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 204 || response.statusCode == 200) {
        _threads.removeWhere((t) => t.id == threadId);
        if (_activeThreadId == threadId) {
          _activeThreadId = null;
          _currentMessages = [];
        }
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  @override
  void dispose() {
    _stopPolling();
    _hubConnection?.stop();
    super.dispose();
  }
}
