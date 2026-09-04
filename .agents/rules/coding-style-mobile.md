# Mobile coding style (Flutter 3.47 and Dart 3)

These rules apply to all Dart and Flutter code written for `happypaws-mobile` (`apps/mobile/`). Following them maintains high performance, strong security, smooth frame rates, and maintainable layered architecture across iOS, Android, and web targets.

## Architecture and layer separation

Organize code by feature using a clean, layered architecture:
- **Presentation layer** (`features/<feature>/presentation/`): Contains UI screens, reusable widgets, and state controllers. Widgets must remain declarative and focused on rendering. Delegate all business logic and API orchestration to controllers.
- **Domain layer** (`features/<feature>/domain/`): Contains pure Dart entities, enums, value objects, and abstract repository contracts. This layer must have zero dependencies on Flutter UI frameworks or third-party storage libraries.
- **Data layer** (`features/<feature>/data/`): Implements domain repository interfaces. Handles HTTP client requests, JSON deserialization, local SQLite or caching logic, and error mapping.
- **Core layer** (`core/`): Houses shared infrastructure such as secure token storage, network interceptors, theme definitions, and common UI components.

## State management and reactive flow

- Use Riverpod or BLoC to manage state reactively and inject dependencies cleanly.
- Never place asynchronous business logic directly inside `StatefulWidget.setState()` calls.
- Use pattern matching on Dart 3 sealed classes or union states (`AsyncValue<T>` or `AsyncData`, `AsyncLoading`, `AsyncError`) to handle loading, success, and error states exhaustively in the UI.

## Secure storage and token management

- Store sensitive authentication tokens, refresh tokens, and encryption keys using `flutter_secure_storage`.
- On Android, always configure `AndroidOptions(encryptedSharedPreferences: true)` for modern cryptographic protection and optimal read performance.
- Cache access tokens in memory after reading them during app initialization. Avoid making asynchronous disk reads to secure storage on every individual HTTP request or widget build.
- Clear both the in-memory cache and secure storage completely upon user sign-out.

## Performance and memory leak prevention

- **Constant constructors**: Use `const` constructors for all immutable widgets. This allows the Flutter framework to short-circuit widget tree rebuilds and maintain 60 to 120 FPS animations.
- **Resource cleanup**: Always override `dispose()` in `StatefulWidget` classes to cancel active `StreamSubscription` instances, dispose `TextEditingController` objects, release `AnimationController` resources, and unbind `FocusNode` instances. Failing to dispose controllers causes permanent memory leaks.
- **List virtualization**: Always use `ListView.builder` or `CustomScrollView` with slivers for dynamic or long lists. Never use standard `Column` or unindexed `ListView` for unbounded data sets.
- **Image caching**: Use `cached_network_image` for remote photos to avoid downloading identical animal images repeatedly.

## Accessibility and responsive design

- Wrap custom icon buttons and gesture detectors inside `Semantics` widgets to provide meaningful labels for TalkBack and VoiceOver screen readers.
- Ensure all interactive touch targets meet the minimum recommended size of 48 by 48 logical pixels.
- Use `LayoutBuilder` or `MediaQuery.sizeOf(context)` to adapt layouts gracefully between mobile phones, foldables, and tablets.
- Respect user system text scaling settings without breaking container layouts.

## Documentation and comments

Explain why the code exists, not what it does. Write comments that clarify platform-specific edge cases, memory management choices, and custom reactive patterns. Omit comments that restate obvious Flutter widget trees.

When writing comments or DartDoc (`///`) documentation, adhere strictly to these rules:
- Write in plain, direct language.
- Do not use em dashes. Use commas, parentheses, or short sentences instead.
- Do not use semicolons in documentation or explanatory text.
- Use the Oxford comma in all lists.
- Use sentence case for all headings and labels.
- Avoid filler words like "utilize", "leverage", "ensure", and "streamline".

---

## Example scenarios

Use these code snippets as blueprints when writing or refactoring mobile features.

### 1. Domain model and repository contract

This scenario defines a rescue entity and its abstract repository contract in pure Dart.

```dart
import 'package:meta/meta.dart';

enum RescueUrgency { critical, moderate, low }
enum RescueStatus { reported, inTransit, receivedByVet, completed }

@immutable
class RescueCase {
  final String id;
  final String description;
  final String animalType;
  final RescueStatus status;
  final RescueUrgency urgency;
  final String photoUrl;
  final double latitude;
  final double longitude;
  final DateTime createdAt;

  const RescueCase({
    required this.id,
    required this.description,
    required this.animalType,
    required this.status,
    required this.urgency,
    required this.photoUrl,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
  });
}

abstract interface class IRescueRepository {
  Future<RescueCase> reportRescue({
    required String description,
    required String animalType,
    required double latitude,
    required double longitude,
    required String photoBase64,
  });

  Future<List<RescueCase>> getNearbyRescues({
    required double latitude,
    required double longitude,
    double radiusKm = 15.0,
  });
}
```

### 2. Secure token storage service with in-memory caching

This service uses `flutter_secure_storage` to protect JWT tokens while avoiding disk I/O bottlenecks.

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureTokenService {
  final FlutterSecureStorage _secureStorage;
  
  // In-memory cache prevents disk read delays on frequent network requests
  String? _cachedAccessToken;

  SecureTokenService({FlutterSecureStorage? storage})
      : _secureStorage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  static const String _accessTokenKey = 'hp_access_token';
  static const String _refreshTokenKey = 'hp_refresh_token';

  Future<String?> getAccessToken() async {
    if (_cachedAccessToken != null) {
      return _cachedAccessToken;
    }

    _cachedAccessToken = await _secureStorage.read(key: _accessTokenKey);
    return _cachedAccessToken;
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _cachedAccessToken = accessToken;

    await Future.wait([
      _secureStorage.write(key: _accessTokenKey, value: accessToken),
      _secureStorage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
  }

  Future<void> clearTokens() async {
    _cachedAccessToken = null;
    await Future.wait([
      _secureStorage.delete(key: _accessTokenKey),
      _secureStorage.delete(key: _refreshTokenKey),
    ]);
  }
}
```

### 3. State management controller

This controller handles asynchronous report submissions, manages loading and error states, and coordinates with repository contracts.

```dart
import 'package:flutter/foundation.dart';
import '../domain/models/rescue_case.dart';
import '../domain/repositories/rescue_repository.dart';

sealed class RescueSubmissionState {
  const RescueSubmissionState();
}

final class RescueInitialState extends RescueSubmissionState {
  const RescueInitialState();
}

final class RescueSubmittingState extends RescueSubmissionState {
  const RescueSubmittingState();
}

final class RescueSuccessState extends RescueSubmissionState {
  final RescueCase rescueCase;
  const RescueSuccessState(this.rescueCase);
}

final class RescueErrorState extends RescueSubmissionState {
  final String errorMessage;
  const RescueErrorState(this.errorMessage);
}

class RescueReportController extends ChangeNotifier {
  final IRescueRepository _repository;
  
  RescueSubmissionState _state = const RescueInitialState();
  RescueSubmissionState get state => _state;

  RescueReportController(this._repository);

  Future<void> submitReport({
    required String description,
    required String animalType,
    required double latitude,
    required double longitude,
    required String photoBase64,
  }) async {
    _state = const RescueSubmittingState();
    notifyListeners();

    try {
      final rescue = await _repository.reportRescue(
        description: description,
        animalType: animalType,
        latitude: latitude,
        longitude: longitude,
        photoBase64: photoBase64,
      );

      _state = RescueSuccessState(rescue);
      notifyListeners();
    } catch (error) {
      _state = RescueErrorState(
        'Failed to submit rescue report. Please check your connection and try again.',
      );
      notifyListeners();
    }
  }
}
```

### 4. UI widget with clean lifecycle management and accessibility

This widget demonstrates explicit controller disposal, accessibility semantics, and responsive design.

```dart
import 'package:flutter/material.dart';
import '../domain/models/rescue_case.dart';
import 'rescue_report_controller.dart';

class RescueReportScreen extends StatefulWidget {
  final RescueReportController controller;

  const RescueReportScreen({
    super.key,
    required this.controller,
  });

  @override
  State<RescueReportScreen> createState() => _RescueReportScreenState();
}

class _RescueReportScreenState extends State<RescueReportScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers must be explicitly disposed to prevent permanent memory leaks
  late final TextEditingController _descriptionController;
  late final TextEditingController _animalTypeController;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    _animalTypeController = TextEditingController(text: 'Dog');
  }

  @override
  void dispose() {
    // Release native text input resources immediately when screen is unmounted
    _descriptionController.dispose();
    _animalTypeController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Default mock coordinates for demonstration
    widget.controller.submitReport(
      description: _descriptionController.text.trim(),
      animalType: _animalTypeController.text.trim(),
      latitude: 6.9271,
      longitude: 79.8612,
      photoBase64: 'sample_base64_encoded_image_data',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report emergency rescue'),
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final state = widget.controller.state;

          if (state is RescueSubmittingState) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is RescueSuccessState) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.green, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'Rescue case reported successfully',
                      style: theme.textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Responders within the vicinity have been alerted.',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state is RescueErrorState) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        state.errorMessage,
                        style: TextStyle(color: theme.colorScheme.onErrorContainer),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _animalTypeController,
                    decoration: const InputDecoration(
                      labelText: 'Animal type',
                      hintText: 'e.g. Dog, Cat, Bird',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please specify the animal type';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Incident description and visible injuries',
                      hintText: 'Describe condition, location landmarks, and immediate hazards',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().length < 10) {
                        return 'Please provide at least 10 characters of description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Semantics(
                    button: true,
                    label: 'Submit emergency rescue report',
                    child: ElevatedButton(
                      onPressed: _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text('Submit report'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
```
