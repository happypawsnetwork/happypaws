import 'package:meta/meta.dart';

@immutable
class VerificationTokenResponse {
  final String verificationToken;

  const VerificationTokenResponse({required this.verificationToken});

  factory VerificationTokenResponse.fromJson(Map<String, dynamic> json) {
    return VerificationTokenResponse(
      verificationToken: json['verificationToken'] as String,
    );
  }
}

@immutable
class MobileLoginResponse {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  const MobileLoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory MobileLoginResponse.fromJson(Map<String, dynamic> json) {
    return MobileLoginResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresIn: json['expiresIn'] as int,
    );
  }
}
