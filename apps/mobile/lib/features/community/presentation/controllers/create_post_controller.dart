import 'package:flutter/material.dart';

import '../../domain/models/post.dart';
import '../../domain/repositories/i_post_repository.dart';

enum CreatePostState { idle, submitting, success, error }

class CreatePostController extends ChangeNotifier {
  final IPostRepository _repository;

  CreatePostState _state = CreatePostState.idle;
  CreatePostState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  PostType? _selectedType;
  PostType? get selectedType => _selectedType;

  // Shared fields
  List<String> photos = [];
  String title = '';
  String body = '';
  String species = '';
  String animalName = '';
  String locationLabel = '';
  double? lat;
  double? lon;

  // Adoption lifestyle expectations
  String? _lifestyleHomeSize;
  String? get lifestyleHomeSize => _lifestyleHomeSize;
  set lifestyleHomeSize(String? value) {
    _lifestyleHomeSize = value;
    notifyListeners();
  }

  bool _lifestyleRequiresEnclosedYard = false;
  bool get lifestyleRequiresEnclosedYard => _lifestyleRequiresEnclosedYard;
  set lifestyleRequiresEnclosedYard(bool value) {
    _lifestyleRequiresEnclosedYard = value;
    notifyListeners();
  }

  bool _lifestyleGoodWithChildren = true;
  bool get lifestyleGoodWithChildren => _lifestyleGoodWithChildren;
  set lifestyleGoodWithChildren(bool value) {
    _lifestyleGoodWithChildren = value;
    notifyListeners();
  }

  String? _lifestyleActivityTempo;
  String? get lifestyleActivityTempo => _lifestyleActivityTempo;
  set lifestyleActivityTempo(String? value) {
    _lifestyleActivityTempo = value;
    notifyListeners();
  }

  List<String> _lifestyleGoodWithPets = [];
  List<String> get lifestyleGoodWithPets => _lifestyleGoodWithPets;
  set lifestyleGoodWithPets(List<String> value) {
    _lifestyleGoodWithPets = value;
    notifyListeners();
  }

  // Rescue specific
  String? urgencyLevel;
  String? aiTriageReason;

  // Foster specific
  String? parentPostId;

  // Transport specific
  String dropoffLocationLabel = '';
  double? dropoffLat;
  double? dropoffLon;

  // Vet specific
  String clinicName = '';
  DateTime? vetVisitDate;
  bool needsTransport = false;

  // Sponsor specific
  double? sponsorAmount;
  List<String> sponsorProofDocs = [];

  List<Map<String, dynamic>> myRescues = [];
  bool isLoadingRescues = false;

  CreatePostController(this._repository);

  Future<void> loadMyRescues() async {
    isLoadingRescues = true;
    notifyListeners();
    myRescues = await _repository.getMyRescues();
    isLoadingRescues = false;
    notifyListeners();
  }

  void selectType(PostType type) {
    _selectedType = type;
    notifyListeners();
  }

  void reset() {
    photos.clear();
    title = '';
    body = '';
    species = '';
    animalName = '';
    locationLabel = '';
    lat = null;
    lon = null;
    urgencyLevel = null;
    aiTriageReason = null;
    parentPostId = null;
    dropoffLocationLabel = '';
    dropoffLat = null;
    dropoffLon = null;
    clinicName = '';
    vetVisitDate = null;
    needsTransport = false;
    sponsorAmount = null;
    sponsorProofDocs.clear();
    myRescues.clear();
    _state = CreatePostState.idle;
    _errorMessage = null;

    _lifestyleHomeSize = null;
    _lifestyleRequiresEnclosedYard = false;
    _lifestyleGoodWithChildren = true;
    _lifestyleActivityTempo = null;
    _lifestyleGoodWithPets = [];

    notifyListeners();
  }

  bool isAssessingUrgency = false;

  Future<void> assessRescueUrgency() async {
    isAssessingUrgency = true;
    notifyListeners();

    try {
      final result = await _repository.assessRescueUrgency(photos);
      urgencyLevel = result.urgencyLevel;
      aiTriageReason = result.reason;
    } catch (e) {
      urgencyLevel = 'Medium';
      aiTriageReason = null;
    } finally {
      isAssessingUrgency = false;
      notifyListeners();
    }
  }

  void setUrgencyLevel(String level) {
    urgencyLevel = level;
    notifyListeners();
  }

  Future<void> submitPost() async {
    _state = CreatePostState.submitting;
    notifyListeners();

    try {
      final data = {
        'type': _selectedType?.name ?? PostType.adoptionListing.name,
        'title': title,
        'body': body,
        'species': species,
        'animalSpecies': species,
        'animalName': animalName,
        'locationLabel': locationLabel,
        'lat': lat,
        'lon': lon,
        'latitude': lat,
        'longitude': lon,
        'urgencyLevel': urgencyLevel,
        'aiTriageReason': aiTriageReason,
        'parentPostId': parentPostId,
        'dropoffLocationLabel': dropoffLocationLabel,
        'dropoffLat': dropoffLat,
        'dropoffLon': dropoffLon,
        'clinicName': clinicName,
        'vetClinicName': clinicName,
        'vetVisitDate': vetVisitDate?.toIso8601String(),
        'vetAppointmentDate': vetVisitDate?.toIso8601String(),
        'needsTransport': needsTransport,
        'vetTransportNeeded': needsTransport,
        'sponsorAmount': sponsorAmount,
        'sponsorEstimatedAmountLkr': sponsorAmount,
        'lifestyleHomeSize': _lifestyleHomeSize,
        'lifestyleRequiresEnclosedYard': _lifestyleRequiresEnclosedYard,
        'lifestyleGoodWithChildren': _lifestyleGoodWithChildren,
        'lifestyleActivityTempo': _lifestyleActivityTempo,
        'lifestyleGoodWithPets': _lifestyleGoodWithPets,
      };

      // Real app would handle multipart file uploads here
      await _repository.createPost(data);
      _state = CreatePostState.success;
      notifyListeners();
    } catch (e) {
      _state = CreatePostState.error;
      _errorMessage = 'Failed to create post.';
      notifyListeners();
    }
  }
}
