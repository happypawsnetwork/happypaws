class RoleVerificationStatus {
  final String role;
  final String status;

  const RoleVerificationStatus({required this.role, required this.status});

  bool get isVerified => status.toLowerCase() == "verified";
  bool get isPending => status.toLowerCase() == "pending";
  bool get isRejected => status.toLowerCase() == "rejected";
  bool get isUnverified => status.toLowerCase() == "unverified";

  factory RoleVerificationStatus.fromJson(Map<String, dynamic> json) {
    return RoleVerificationStatus(
      role: json["role"] as String? ?? "",
      status: json["status"] as String? ?? "Unverified",
    );
  }

  Map<String, dynamic> toJson() => {"role": role, "status": status};
}
