class LifestyleProfile {
  final String? homeSize;
  final bool hasEnclosedYard;
  final bool hasChildren;
  final String? activityTempo;
  final List<String> existingPets;

  const LifestyleProfile({
    this.homeSize,
    this.hasEnclosedYard = false,
    this.hasChildren = false,
    this.activityTempo,
    this.existingPets = const [],
  });

  factory LifestyleProfile.fromJson(Map<String, dynamic> json) {
    return LifestyleProfile(
      homeSize: json['homeSize'] as String?,
      hasEnclosedYard: json['hasEnclosedYard'] as bool? ?? false,
      hasChildren: json['hasChildren'] as bool? ?? false,
      activityTempo: json['activityTempo'] as String?,
      existingPets:
          (json['existingPets'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  LifestyleProfile copyWith({
    String? homeSize,
    bool? hasEnclosedYard,
    bool? hasChildren,
    String? activityTempo,
    List<String>? existingPets,
  }) {
    return LifestyleProfile(
      homeSize: homeSize ?? this.homeSize,
      hasEnclosedYard: hasEnclosedYard ?? this.hasEnclosedYard,
      hasChildren: hasChildren ?? this.hasChildren,
      activityTempo: activityTempo ?? this.activityTempo,
      existingPets: existingPets ?? this.existingPets,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'homeSize': homeSize,
      'hasEnclosedYard': hasEnclosedYard,
      'hasChildren': hasChildren,
      'activityTempo': activityTempo,
      'existingPets': existingPets,
    };
  }
}
