import 'dart:typed_data';

class UserModel {
  final String id;
  String firstName;
  String lastName;
  final String email;
  String phoneNumber;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phoneNumber = '',
  });
}

class ImageRecord {
  final String id;
  final String filename;
  final String dateUploaded;
  Uint8List? imageBytes; 
  String description; // <--- Removed 'final' from here so the ML can update it!
  List<AnnotationMarker> markers;

  ImageRecord({
    required this.id,
    required this.filename,
    required this.dateUploaded,
    this.imageBytes,
    this.description = '',
    List<AnnotationMarker>? markers,
  }) : markers = markers ?? [];
}

class AnnotationMarker {
  final String id;
  final double x;
  final double y;
  List<String> comments;
  List<String> commentTimestamps;
  List<String> noteIds;

  AnnotationMarker({
    required this.id,
    required this.x,
    required this.y,
    List<String>? comments,
    List<String>? commentTimestamps,
    List<String>? noteIds,
  }) : comments = comments ?? [],
       commentTimestamps = commentTimestamps ?? [],
       noteIds = noteIds ?? [];
}