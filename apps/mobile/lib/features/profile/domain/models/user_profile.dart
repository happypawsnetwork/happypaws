import 'package:meta/meta.dart';

import '../../../../core/utils/url_helper.dart';

class UserRole {
  final String name;
  final bool isVerified;
  final bool isVisible;

  const UserRole({
    required this.name,
    required this.isVerified,
    this.isVisible = true,
  });

  factory UserRole.fromJson(Map<String, dynamic> json) {
    return UserRole(
      name: json['name'] as String,
      isVerified: json['isVerified'] as bool? ?? false,
      isVisible: json['isVisible'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'isVerified': isVerified, 'isVisible': isVisible};
  }

  UserRole copyWith({String? name, bool? isVerified, bool? isVisible}) {
    return UserRole(
      name: name ?? this.name,
      isVerified: isVerified ?? this.isVerified,
      isVisible: isVisible ?? this.isVisible,
    );
  }
}

@immutable
class UserProfile {
  final int id;
  final String email;
  final String name;
  final String? avatarUrl;
  final String? tagline;
  final String? username;
  final List<UserRole> roles;
  final int reputationPoints;
  final List<String> trustBadges;

  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  final double? homeLatitude;
  final double? homeLongitude;
  final bool receiveMessages;

  bool get isVerified => roles.any((r) => r.isVerified);

  bool hasRole(String roleName) => roles.any(
    (r) => r.name.trim().toLowerCase() == roleName.trim().toLowerCase(),
  );

  bool get isFoster => hasRole('Foster');
  bool get isTransporter => hasRole('Transporter');
  bool get isSponsor => hasRole('Sponsor');
  bool get isVeterinarian => hasRole('Veterinarian') || hasRole('Vet');

  bool get hasHomeAddress =>
      addressLine1 != null &&
      addressLine1!.trim().isNotEmpty &&
      city != null &&
      city!.trim().isNotEmpty &&
      state != null &&
      state!.trim().isNotEmpty;

  const UserProfile({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    this.tagline,
    this.username,
    required this.roles,
    this.reputationPoints = 0,
    this.trustBadges = const [],
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.homeLatitude,
    this.homeLongitude,
    this.receiveMessages = true,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      email: json['email'] as String,
      name: json['name'] as String? ?? json['fullName'] as String? ?? '',
      avatarUrl: _resolveAvatarUrl(json['avatarUrl'] as String?),
      tagline: json['tagline'] as String?,
      username: json['username'] as String?,
      roles:
          (json['roles'] as List<dynamic>?)?.map((e) {
            if (e is String) return UserRole(name: e, isVerified: false);
            return UserRole.fromJson(e as Map<String, dynamic>);
          }).toList() ??
          [],
      reputationPoints: json['reputationPoints'] as int? ?? 0,
      trustBadges:
          (json['trustBadges'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      addressLine1: json['addressLine1'] as String?,
      addressLine2: json['addressLine2'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      postalCode: json['postalCode'] as String?,
      country: json['country'] as String?,
      homeLatitude: (json['homeLatitude'] as num?)?.toDouble(),
      homeLongitude: (json['homeLongitude'] as num?)?.toDouble(),
      receiveMessages: json['receiveMessages'] as bool? ?? true,
    );
  }

  UserProfile copyWith({
    int? id,
    String? email,
    String? name,
    String? avatarUrl,
    String? tagline,
    String? username,
    List<UserRole>? roles,
    int? reputationPoints,
    List<String>? trustBadges,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    double? homeLatitude,
    double? homeLongitude,
    bool? receiveMessages,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      tagline: tagline ?? this.tagline,
      username: username ?? this.username,
      roles: roles ?? this.roles,
      reputationPoints: reputationPoints ?? this.reputationPoints,
      trustBadges: trustBadges ?? this.trustBadges,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      homeLatitude: homeLatitude ?? this.homeLatitude,
      homeLongitude: homeLongitude ?? this.homeLongitude,
      receiveMessages: receiveMessages ?? this.receiveMessages,
    );
  }

  static String? _resolveAvatarUrl(String? rawUrl) =>
      UrlHelper.resolveUrl(rawUrl);
}
