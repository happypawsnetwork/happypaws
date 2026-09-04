import "dart:io";

import "package:flutter/foundation.dart";

import "../../domain/models/role_verification_status.dart";
import "../../domain/repositories/i_verification_repository.dart";

class VerificationController extends ChangeNotifier {
  final IVerificationRepository _repository;

  VerificationController(this._repository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<RoleVerificationStatus> _roleStatuses = [];
  List<RoleVerificationStatus> get roleStatuses => _roleStatuses;

  String? _selectedRole;
  String? get selectedRole => _selectedRole;

  final Map<String, File> _selectedFiles = {};
  Map<String, File> get selectedFiles => _selectedFiles;

  Future<void> loadStatuses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _roleStatuses = await _repository.getVerificationStatuses();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectRole(String? role) {
    if (_selectedRole != role) {
      _selectedRole = role;
      _selectedFiles.clear();
      notifyListeners();
    }
  }

  void setDocumentFile(String documentType, File file) {
    _selectedFiles[documentType] = file;
    notifyListeners();
  }

  void removeDocumentFile(String documentType) {
    _selectedFiles.remove(documentType);
    notifyListeners();
  }

  bool canSubmit() {
    if (_selectedRole == null) return false;

    switch (_selectedRole) {
      case "Adopter":
      case "Foster":
      case "Sponsor":
        return _selectedFiles.containsKey("GovernmentId");
      case "Transporter":
        return _selectedFiles.containsKey("DrivingLicense") &&
            _selectedFiles.containsKey("VehicleInsurance");
      case "Veterinarian":
        return _selectedFiles.containsKey("GovernmentId") &&
            _selectedFiles.containsKey("VcslCertificate");
      default:
        return false;
    }
  }

  Future<bool> submitVerification() async {
    if (!canSubmit()) return false;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final documentsPayload = <Map<String, String>>[];

      for (final entry in _selectedFiles.entries) {
        final uri = await _repository.uploadDocument(
          file: entry.value,
          documentType: entry.key,
        );
        documentsPayload.add({"documentType": entry.key, "documentUri": uri});
      }

      await _repository.submitVerification(
        requestedRole: _selectedRole!,
        documents: documentsPayload,
      );

      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _selectedRole = null;
    _selectedFiles.clear();
    _errorMessage = null;
    _isSubmitting = false;
    notifyListeners();
  }
}
