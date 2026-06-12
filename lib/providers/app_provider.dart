import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/app_models.dart';
import '../services/api_service.dart';
import 'dart:ui' as ui;

class AppProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  UserModel? _tempRegistrationData;
  String? _tempPassword;
  final List<ImageRecord> _history = [];
  ImageRecord? _activeImage;
  int _activeWorkspaceTab = 0;
  AnnotationMarker? _selectedMarker;
  final Set<String> _compareSelection = {};
  final Map<String, String> _commentNoteIds = {};
  List<ImageRecord> _comparisonRecords = [];
  List<DateTime> _comparisonDates = [];

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  List<ImageRecord> get history => _history;
  ImageRecord? get activeImage => _activeImage;
  int get activeWorkspaceTab => _activeWorkspaceTab;
  AnnotationMarker? get selectedMarker => _selectedMarker;
  Set<String> get compareSelection => _compareSelection;
  List<ImageRecord> get comparisonRecords => _comparisonRecords;
  List<DateTime> get comparisonDates => _comparisonDates;

  String _generateUuidV4() {
    final random = Random();
    final hexDigits = '0123456789abcdef';
    String uuid = '';
    for (int i = 0; i < 36; i++) {
      if (i == 8 || i == 13 || i == 18 || i == 23)
        uuid += '-';
      else if (i == 14)
        uuid += '4';
      else if (i == 19)
        uuid += hexDigits[(random.nextInt(16) & 0x3) | 0x8];
      else
        uuid += hexDigits[random.nextInt(16)];
    }
    return uuid;
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setTempRegistration(
    String first,
    String last,
    String email,
    String password,
  ) {
    _tempRegistrationData = UserModel(
      id: DateTime.now().toString(),
      firstName: first,
      lastName: last,
      email: email,
    );
    _tempPassword = password;
  }

  Future<String?> completeRegistration(
    String q1,
    String a1,
    String q2,
    String a2,
    String q3,
    String a3,
  ) async {
    if (_tempRegistrationData == null || _tempPassword == null)
      return "Missing registration data.";

    setLoading(true);

    String? errorMessage = await ApiService.register(
      email: _tempRegistrationData!.email,
      firstName: _tempRegistrationData!.firstName,
      lastName: _tempRegistrationData!.lastName,
      password: _tempPassword!,
      q1: q1,
      a1: a1,
      q2: q2,
      a2: a2,
      q3: q3,
      a3: a3,
    );

    setLoading(false);
    return errorMessage;
  }

  Future<bool> login(String email, String password) async {
    setLoading(true);
    final responseData = await ApiService.login(email, password);
    if (responseData != null && responseData['object'] != null) {
      final userObj = responseData['object'];
      _currentUser = UserModel(
        id: responseData['uuid']?.toString() ?? DateTime.now().toString(),
        firstName: userObj['firstName'] ?? 'User',
        lastName: userObj['lastName'] ?? '',
        email: email,
      );
      await fetchHistoryData();
      setLoading(false);
      return true;
    }
    setLoading(false);
    return false;
  }

  Future<void> fetchHistoryData() async {
    if (_currentUser == null) return;
    final results = await ApiService.fetchHistory(_currentUser!.email);
    Map<String, Uint8List?> localBytesBackup = {};
    for (var record in _history) {
      if (record.imageBytes != null)
        localBytesBackup[record.id] = record.imageBytes;
    }
    _history.clear();

    for (var item in results) {
      try {
        String rawDesc = item['description'] ?? '';
        String cleanDesc = rawDesc;
        try {
          final parsed = jsonDecode(rawDesc);
          if (parsed is Map<String, dynamic> &&
              parsed.containsKey('description'))
            cleanDesc = parsed['description'];
        } catch (_) {
          cleanDesc = rawDesc
              .replaceAll("{description: ", "")
              .replaceAll(", source: redis}", "")
              .trim();
        }
        cleanDesc = cleanDesc
            .replaceAll(r'\n', '\n')
            .replaceAll(r'\u2019', "'");

        String id = item['id']?.toString() ?? DateTime.now().toString();
        Uint8List? restoredBytes = localBytesBackup[id];

        // --- NEW DECODING & FILENAME FIX ---
        String dbUrl = item['url'] ?? '';
        String displayFilename =
            item['name'] ?? item['fileName'] ?? 'History Image';

        if (displayFilename.startsWith('data:image')) {
          displayFilename = 'Uploaded Image';
        }

        if (restoredBytes == null && dbUrl.startsWith('data:image')) {
          try {
            final String base64String = dbUrl.split(',').last;
            restoredBytes = base64Decode(base64String);
          } catch (e) {
            debugPrint("Failed to decode base64 from DB: $e");
          }
        }
        // --- END DECODING & FILENAME FIX ---

        if (restoredBytes == null) {
          try {
            String? b64 = html.window.localStorage['img_$id'];
            if (b64 != null) restoredBytes = base64Decode(b64);
          } catch (e) {}
        }

        final newRecord = ImageRecord(
          id: id,
          filename: displayFilename,
          dateUploaded: item['createdAt'] != null
              ? DateFormat('yyyy-MM-dd').format(
                  DateTime.tryParse(item['createdAt'])?.toLocal() ??
                      DateTime.now(),
                )
              : DateFormat('yyyy-MM-dd').format(DateTime.now()),
          description: cleanDesc,
          imageBytes: restoredBytes,
        );

        if (item['annotations'] != null && item['annotations'] is List) {
          for (var ann in item['annotations']) {
            final marker = AnnotationMarker(
              id: ann['id']?.toString() ?? _generateUuidV4(),
              x: double.tryParse(ann['x']?.toString() ?? '0') ?? 0.0,
              y: double.tryParse(ann['y']?.toString() ?? '0') ?? 0.0,
            );
            if (ann['notes'] != null && ann['notes'] is List) {
              for (var note in ann['notes']) {
                String noteBody = note['body']?.toString() ?? '';
                if (noteBody.isNotEmpty) {
                  _commentNoteIds[noteBody] = note['id']?.toString() ?? '';
                  marker.comments.add(noteBody);
                  String timeString = DateFormat(
                    'MMM dd yyyy, hh:mm a',
                  ).format(DateTime.now()).toUpperCase();
                  if (note['createdAt'] != null)
                    timeString = DateFormat('MMM dd yyyy, hh:mm a')
                        .format(
                          DateTime.tryParse(note['createdAt'])?.toLocal() ??
                              DateTime.now(),
                        )
                        .toUpperCase();
                  marker.commentTimestamps.add(timeString);
                }
              }
            }
            newRecord.markers.add(marker);
          }
        }
        _history.add(newRecord);
      } catch (e) {
        debugPrint('Parse error: $e');
      }
    }
    notifyListeners();
  }

  Future<void> pickAndUploadImage({
    ImageSource source = ImageSource.gallery,
  }) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);
    if (image != null && _currentUser != null) {
      if (image.name.toLowerCase().endsWith('.pdf') ||
          image.name.toLowerCase().endsWith('.doc'))
        return;
      final bytes = await image.readAsBytes();
      await uploadImageBytes(bytes, image.name);
    }
  }

  // --- NEW BACKGROUND PROCESSING FIX ---
  Future<void> uploadImageBytes(Uint8List bytes, String filename) async {
    if (_currentUser == null) return;

    // 1. Show loading spinner briefly to process the database save
    setLoading(true);

    // 2. Instantly save to DB with a temporary description so we get a real ID
    String tempDesc =
        "Analysis in progress... You can add annotations while waiting.";
    String? dbId = await ApiService.createImageRecord(
      tempDesc,
      bytes,
      _currentUser!.email,
      filename,
    );
    final realId = dbId ?? DateTime.now().toString();

    try {
      html.window.localStorage['img_$realId'] = base64Encode(bytes);
    } catch (e) {}

    // 3. Show the image on the screen IMMEDIATELY
    final newRecord = ImageRecord(
      id: realId,
      filename: filename,
      dateUploaded: DateFormat('yyyy-MM-dd, hh:mm a').format(DateTime.now()),
      imageBytes: bytes,
      description: tempDesc,
    );

    _history.insert(0, newRecord);
    setActiveImage(newRecord);

    // 4. STOP THE SPINNER NOW! (Unblocks the UI so you can annotate)
    setLoading(false);

    // 5. Run ML Description in the background
    try {
      String rawDescription = await ApiService.describeImage(bytes, filename);
      String cleanDesc = rawDescription;
      try {
        final parsed = jsonDecode(rawDescription);
        if (parsed is Map<String, dynamic> && parsed.containsKey('description'))
          cleanDesc = parsed['description'];
      } catch (_) {
        cleanDesc = rawDescription
            .replaceAll("{description: ", "")
            .replaceAll(", source: redis}", "")
            .trim();
      }
      cleanDesc = cleanDesc.replaceAll(r'\n', '\n').replaceAll(r'\u2019', "'");

      // Silently update the UI with the finished ML description!
      newRecord.description = cleanDesc;
      notifyListeners();
      await ApiService.updateImageDescription(
        imageId: realId,
        email: _currentUser!.email,
        name: filename,
        url: 'data:image/png;base64,${base64Encode(bytes)}',
        description: cleanDesc,
      );
    } catch (e) {
      // If the 504 Timeout happens, let the user know gracefully
      newRecord.description =
          "Analysis timed out. The ML server took too long to respond.";
      notifyListeners();
    }
  }
  // --- END BACKGROUND PROCESSING FIX ---

  void removeImageFromHistory(String id) async {
    if (_currentUser != null) {
      await ApiService.deleteImageRecord(id, _currentUser!.email);
      _history.removeWhere((record) => record.id == id);
      _compareSelection.remove(id);
      try {
        html.window.localStorage.remove('img_$id');
      } catch (e) {}
      if (_activeImage?.id == id) clearWorkspace();
      notifyListeners();
    }
  }

  void toggleCompareSelection(String id) {
    if (_compareSelection.contains(id)) {
      _compareSelection.remove(id);
    } else {
      if (_compareSelection.length < 2) _compareSelection.add(id);
    }
    notifyListeners();
  }

  Future<void> executeComparisonWithDates(
    String id1,
    DateTime date1,
    String id2,
    DateTime date2,
  ) async {
    setLoading(true);
    final r1 = _history.firstWhere((r) => r.id == id1);
    final r2 = _history.firstWhere((r) => r.id == id2);
    ImageRecord older, newer;
    DateTime oldDate, newDate;

    if (date1.isBefore(date2)) {
      older = r1;
      newer = r2;
      oldDate = date1;
      newDate = date2;
    } else {
      older = r2;
      newer = r1;
      oldDate = date2;
      newDate = date1;
    }

    _comparisonRecords = [older, newer];
    _comparisonDates = [oldDate, newDate];

    if (older.imageBytes != null && newer.imageBytes != null) {
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(recorder);
      final ui.Codec codec1 = await ui.instantiateImageCodec(older.imageBytes!);
      final ui.Image i1 = (await codec1.getNextFrame()).image;
      final ui.Codec codec2 = await ui.instantiateImageCodec(newer.imageBytes!);
      final ui.Image i2 = (await codec2.getNextFrame()).image;
      canvas.drawImage(i1, ui.Offset.zero, ui.Paint());
      canvas.drawImage(i2, ui.Offset(i1.width.toDouble(), 0), ui.Paint());
      final ui.Image merged = await recorder.endRecording().toImage(
        i1.width + i2.width,
        max(i1.height, i2.height),
      );
      final ByteData? data = await merged.toByteData(
        format: ui.ImageByteFormat.png,
      );

      String? mlResult = await ApiService.compareImages(
        data!.buffer.asUint8List(),
      );

      final newRecord = ImageRecord(
        id: DateTime.now().toString(),
        filename: "Comparison Report",
        dateUploaded: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        imageBytes: newer.imageBytes,
        description: mlResult ?? "Analysis complete.",
      );
      setActiveImage(newRecord);
    }
    _compareSelection.clear();
    setLoading(false);
  }

  void logout() {
    _currentUser = null;
    clearWorkspace();
    _history.clear();
    _compareSelection.clear();
    notifyListeners();
  }

  void clearWorkspace() {
    _activeImage = null;
    _selectedMarker = null;
    _activeWorkspaceTab = 0;
    _comparisonRecords.clear();
    _comparisonDates.clear();
    notifyListeners();
  }

  void setActiveImage(ImageRecord record) {
    _activeImage = record;
    _activeWorkspaceTab = 0;
    _selectedMarker = null;
    notifyListeners();
  }

  void setWorkspaceTab(int index) {
    _activeWorkspaceTab = index;
    notifyListeners();
  }

  void saveCroppedImage(ImageRecord record, Uint8List croppedBytes) {
    record.imageBytes = croppedBytes;
    record.markers.clear();
    _selectedMarker = null;
    notifyListeners();
  }

  void selectMarker(AnnotationMarker marker) {
    _selectedMarker = marker;
    _activeWorkspaceTab = 1;
    notifyListeners();
  }

  void addMarker(double x, double y) async {
    if (_activeImage != null &&
        _currentUser != null &&
        _activeImage!.filename != "Comparison Report") {
      final markerId = _generateUuidV4();
      await ApiService.saveAnnotation(
        imageId: _activeImage!.id,
        annotationId: markerId,
        x: x,
        y: y,
        label: "Marker",
        email: _currentUser!.email,
      );
      final newMarker = AnnotationMarker(id: markerId, x: x, y: y);
      _activeImage!.markers.add(newMarker);
      _selectedMarker = newMarker;
      _activeWorkspaceTab = 1;
      notifyListeners();
    }
  }

  void addCommentToMarker(String text) async {
    if (_selectedMarker != null &&
        _activeImage != null &&
        _currentUser != null &&
        text.trim().isNotEmpty) {
      final noteId = _generateUuidV4();
      final cleanText = text.trim();
      await ApiService.addNote(
        imageId: _activeImage!.id,
        annotationId: _selectedMarker!.id,
        noteId: noteId,
        title: "Comment",
        body: cleanText,
        email: _currentUser!.email,
      );
      _commentNoteIds[cleanText] = noteId;
      _selectedMarker!.comments.add(cleanText);
      _selectedMarker!.commentTimestamps.add(
        DateFormat('MMM dd yyyy, hh:mm a').format(DateTime.now()).toUpperCase(),
      );
      _selectedMarker = null;
      notifyListeners();
    }
  }

  void removeComment(AnnotationMarker marker, int index) async {
    if (_activeImage != null && _currentUser != null) {
      final String commentText = marker.comments[index];
      final String? noteId = _commentNoteIds[commentText];
      if (noteId != null) {
        await ApiService.deleteNote(
          imageId: _activeImage!.id,
          annotationId: marker.id,
          noteId: noteId,
          email: _currentUser!.email,
        );
        _commentNoteIds.remove(commentText);
      }
      marker.comments.removeAt(index);
      if (marker.commentTimestamps.length > index)
        marker.commentTimestamps.removeAt(index);
      if (marker.comments.isEmpty) {
        await ApiService.deleteAnnotation(
          imageId: _activeImage!.id,
          annotationId: marker.id,
          email: _currentUser!.email,
        );
        _activeImage!.markers.removeWhere((m) => m.id == marker.id);
        if (_selectedMarker?.id == marker.id) _selectedMarker = null;
      }
      notifyListeners();
    }
  }

  void updateUserProfile(String first, String last, String phone) {}
  Future<void> runHistoryComparison() async {}
}
