import 'package:meta/meta.dart';

@immutable
class LifestyleExpectations {
  final String? homeSize;
  final bool requiresEnclosedYard;
  final bool goodWithChildren;
  final String? activityTempo;
  final List<String> goodWithPets;

  const LifestyleExpectations({
    this.homeSize,
    this.requiresEnclosedYard = false,
    this.goodWithChildren = true,
    this.activityTempo,
    this.goodWithPets = const [],
  });

  factory LifestyleExpectations.fromJson(Map<String, dynamic> json) {
    return LifestyleExpectations(
      homeSize: json['homeSize'] as String?,
      requiresEnclosedYard: json['requiresEnclosedYard'] as bool? ?? false,
      goodWithChildren: json['goodWithChildren'] as bool? ?? true,
      activityTempo: json['activityTempo'] as String?,
      goodWithPets:
          (json['goodWithPets'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'homeSize': homeSize,
      'requiresEnclosedYard': requiresEnclosedYard,
      'goodWithChildren': goodWithChildren,
      'activityTempo': activityTempo,
      'goodWithPets': goodWithPets,
    };
  }
}
