import 'package:meta/meta.dart';

import 'lifestyle_expectations.dart';
import 'post_media.dart';
import 'vet_request_details.dart';
import 'sponsorship_details.dart';

enum PostType {
  rescueAlert,
  fosterUpdate,
  adoptionListing,
  highlight,
  transportRequest,
  vetRequest,
  sponsorshipRequest,
}

enum PostStatus {
  active,
  fostered,
  assigned,
  completed,
  pendingApproval,
  funded,
  rejected,
  cancelled,
}

@immutable
class Post {
  final String id;
  final PostType type;
  final PostStatus status;
  final String title;
  final String body;
  final int likeCount;
  final bool isLikedByCurrentUser;
  final int authorId;
  final String authorDisplayName;
  final String? authorAvatarUrl;
  final String? authorTagline;
  final String? locationLabel;
  final double? latitude;
  final double? longitude;
  final String? animalSpecies;
  final String? animalName;
  final String? animalDescription;
  final String? firstPhotoUrl;
  final int photoCount;
  final String? parentPostId;
  final String? parentPostTitle;
  final int? applicantCount;
  final VetRequestDetails? vetDetails;
  final SponsorshipDetails? sponsorshipDetails;
  final LifestyleExpectations? expectations;
  final List<PostMedia> media;
  final DateTime createdAt;
  final String? urgencyLevel;
  final String? aiTriageReason;
  final bool isUrgencyManuallyOverridden;
  final bool isRecommended;

  const Post({
    required this.id,
    required this.type,
    required this.status,
    required this.title,
    required this.body,
    required this.likeCount,
    required this.isLikedByCurrentUser,
    required this.authorId,
    required this.authorDisplayName,
    this.authorAvatarUrl,
    this.authorTagline,
    this.locationLabel,
    this.latitude,
    this.longitude,
    this.animalSpecies,
    this.animalName,
    this.animalDescription,
    this.firstPhotoUrl,
    required this.photoCount,
    this.parentPostId,
    this.parentPostTitle,
    this.applicantCount,
    this.vetDetails,
    this.sponsorshipDetails,
    this.expectations,
    required this.media,
    required this.createdAt,
    this.urgencyLevel,
    this.aiTriageReason,
    this.isUrgencyManuallyOverridden = false,
    this.isRecommended = false,
  });

  Post copyWith({
    String? id,
    PostType? type,
    PostStatus? status,
    String? title,
    String? body,
    int? likeCount,
    bool? isLikedByCurrentUser,
    int? authorId,
    String? authorDisplayName,
    String? authorAvatarUrl,
    String? authorTagline,
    String? locationLabel,
    double? latitude,
    double? longitude,
    String? animalSpecies,
    String? animalName,
    String? animalDescription,
    String? firstPhotoUrl,
    int? photoCount,
    String? parentPostId,
    String? parentPostTitle,
    int? applicantCount,
    VetRequestDetails? vetDetails,
    SponsorshipDetails? sponsorshipDetails,
    LifestyleExpectations? expectations,
    List<PostMedia>? media,
    DateTime? createdAt,
    String? urgencyLevel,
    String? aiTriageReason,
    bool? isUrgencyManuallyOverridden,
    bool? isRecommended,
  }) {
    return Post(
      id: id ?? this.id,
      type: type ?? this.type,
      status: status ?? this.status,
      title: title ?? this.title,
      body: body ?? this.body,
      likeCount: likeCount ?? this.likeCount,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
      authorId: authorId ?? this.authorId,
      authorDisplayName: authorDisplayName ?? this.authorDisplayName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      authorTagline: authorTagline ?? this.authorTagline,
      locationLabel: locationLabel ?? this.locationLabel,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      animalSpecies: animalSpecies ?? this.animalSpecies,
      animalName: animalName ?? this.animalName,
      animalDescription: animalDescription ?? this.animalDescription,
      firstPhotoUrl: firstPhotoUrl ?? this.firstPhotoUrl,
      photoCount: photoCount ?? this.photoCount,
      parentPostId: parentPostId ?? this.parentPostId,
      parentPostTitle: parentPostTitle ?? this.parentPostTitle,
      applicantCount: applicantCount ?? this.applicantCount,
      vetDetails: vetDetails ?? this.vetDetails,
      sponsorshipDetails: sponsorshipDetails ?? this.sponsorshipDetails,
      expectations: expectations ?? this.expectations,
      media: media ?? this.media,
      createdAt: createdAt ?? this.createdAt,
      urgencyLevel: urgencyLevel ?? this.urgencyLevel,
      aiTriageReason: aiTriageReason ?? this.aiTriageReason,
      isUrgencyManuallyOverridden:
          isUrgencyManuallyOverridden ?? this.isUrgencyManuallyOverridden,
      isRecommended: isRecommended ?? this.isRecommended,
    );
  }
}
