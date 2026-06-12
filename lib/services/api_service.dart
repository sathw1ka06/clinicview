import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  // Strictly reading from .env file
  static String get authBaseUrl => dotenv.env['AUTH_BASE_URL']!;
  static String get legalBaseUrl => dotenv.env['LEGAL_BASE_URL']!;
  static String get mlBaseUrl => dotenv.env['ML_BASE_URL']!;

  static String get authKey => dotenv.env['AUTH_KEY']!;
  static String get legalKey => dotenv.env['LEGAL_KEY']!;
  static String get mlKey => dotenv.env['ML_KEY']!;

  static String get authProduct => dotenv.env['AUTH_PRODUCT']!;
  static String get origin => dotenv.env['ORIGIN']!;
  static String get referer => dotenv.env['REFERER']!;

  // --- 1) LOGIN ---
  static Future<Map<String, dynamic>?> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$authBaseUrl/'),
        headers: {
          'Accept': 'application/json',
          'Accept-Language': 'en',
          'Ocp-Apim-Subscription-Key': authKey,
          'User-locale': 'en-US',
          'email': email,
          'password': password,
          'product': authProduct,
          'externalApp': 'true',
          'Origin': 'https://cliniview.dfoundry.ai',
          'Referer': 'https://cliniview.dfoundry.ai/',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Login API Error: $e');
    }
    return null;
  }

  // --- 2) REGISTER ---
  static Future<String?> register({
    required String email,
    required String firstName,
    required String lastName,
    required String password,
    required String q1,
    required String a1,
    required String q2,
    required String a2,
    required String q3,
    required String a3,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$authBaseUrl/users/register'),
        headers: {
          'Accept': 'application/json, text/plain, */*',
          'Accept-Language': 'en',
          'Content-Type': 'application/json',
          'Ocp-Apim-Subscription-Key': authKey,
          'product': authProduct,
          'tenantID': 'datafoundry',
          'managerEmailID': 'john.doe@datafoundry.ai',
          'externalApp': 'true',
          'Origin': 'https://cliniview.dfoundry.ai',
          'Referer': 'https://cliniview.dfoundry.ai/',
        },
        body: jsonEncode({
          "email": email,
          "firstName": firstName,
          "lastName": lastName,
          "password": password,
          "securityQuestion1": q1,
          "securityQuestion2": q2,
          "securityQuestion3": q3,
          "securityAnswer1": a1,
          "securityAnswer2": a2,
          "securityAnswer3": a3,
          "tenantID": "datafoundry",
          "managerEmailID": "john.doe@datafoundry.ai",
        }),
      );

      // If successful, return null (meaning no errors)
      if (response.statusCode == 200 || response.statusCode == 201) {
        return null;
      } else {
        // If it fails, try to grab the exact error message from the backend
        try {
          final errorData = jsonDecode(response.body);
          return errorData['message'] ??
              errorData['error'] ??
              "Password must be at least 8 characters and include numbers/symbols.";
        } catch (_) {
          return "Registration failed. Ensure password is 8+ characters with numbers & symbols.";
        }
      }
    } catch (e) {
      debugPrint(
        "REAL ERROR TRIGGERED: $e",
      ); // <-- This exposes the hidden crash!
      return "Network error. Please check your connection.";
    }
  }

  // --- 3) CREATE IMAGE RECORD ---
  static Future<String?> createImageRecord(
    String description,
    Uint8List imageBytes,
    String email,
    String filename,
  ) async {
    try {
      String base64Image = 'data:image/png;base64,${base64Encode(imageBytes)}';

      final response = await http.post(
        Uri.parse('$legalBaseUrl/image-annotations'),
        headers: {
          'Content-Type': 'application/json',
          'apiKey': legalKey,
          'user-email': email,
          'Origin': origin,
          'Referer': referer,
        },
        body: jsonEncode({
          "name": filename, // <--- NO MORE HARDCODED WOUND IMAGE!
          "url": base64Image,
          "description": description,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data["id"];
      } else {
        debugPrint("Save Failed. Backend returned: ${response.body}");
      }
    } catch (e) {
      debugPrint("Create Image Record Error: $e");
    }
    return null;
  }

  // --- UPDATE IMAGE DESCRIPTION ---
  static Future<bool> updateImageDescription({
    required String imageId,
    required String email,
    required String name,
    required String url,
    required String description,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$legalBaseUrl/image-annotations/$imageId'),
        headers: {
          'Accept': '*/*',
          'Content-Type': 'application/json',
          'apiKey': legalKey,
          'user-email': email,
          'Origin': origin,
          'Referer': referer,
        },
        body: jsonEncode({
          "name": name,
          "url": url,
          "description": description,
        }),
      );

      debugPrint('Update Description Status: ${response.statusCode}');
      debugPrint('Update Description Body: ${response.body}');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Update Image Description Error: $e');
      return false;
    }
  }

  // --- 4) ML DESCRIBE IMAGE ---
  static Future<String> describeImage(Uint8List bytes, String filename) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$mlBaseUrl/describe-image'),
      );
      request.headers['apiKey'] = mlKey;
      request.files.add(
        http.MultipartFile.fromBytes('image', bytes, filename: filename),
      );
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data["description"] ?? response.body;
      }
    } catch (e) {
      debugPrint("ML Error: $e");
    }
    return "Description unavailable.";
  }

  // --- 5) COMPARE MULTI-IMAGE API ---
  static Future<String?> compareImages(Uint8List mergedImageBytes) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$mlBaseUrl/describemulti-image'),
      );

      request.headers.addAll({
        'apiKey': mlKey,
        'Origin': 'https://cliniview.dfoundry.ai',
        'Referer': 'https://cliniview.dfoundry.ai/',
      });

      // FIX: The ML backend expects a single merged image file!
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          mergedImageBytes,
          filename: 'merged_comparison.png',
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final data = jsonDecode(response.body);
          return data["description"] ?? response.body;
        } catch (e) {
          return response.body;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // --- 6) SAVE ANNOTATION ---
  static Future<bool> saveAnnotation({
    required String imageId,
    required String annotationId,
    required double x,
    required double y,
    required String label,
    required String email,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$legalBaseUrl/image-annotations/$imageId/annotations'),
        headers: {
          'Content-Type': 'application/json',
          'apiKey': legalKey,
          'user-email': email,
        },
        body: jsonEncode({
          "id": annotationId,
          "x": x,
          "y": y,
          "label": label,
          "notes": [],
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // --- 7) ADD NOTE ---
  static Future<bool> addNote({
    required String imageId,
    required String annotationId,
    required String noteId,
    required String title,
    required String body,
    required String email,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(
          '$legalBaseUrl/image-annotations/$imageId/annotations/$annotationId/notes',
        ),
        headers: {
          'Content-Type': 'application/json',
          'apiKey': legalKey,
          'user-email': email,
        },
        body: jsonEncode({
          "id": noteId,
          "title": title,
          "body": body,
          "createdAt": DateTime.now().toUtc().toIso8601String(),
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // --- 8) DELETE NOTE ---
  static Future<bool> deleteNote({
    required String imageId,
    required String annotationId,
    required String noteId,
    required String email,
  }) async {
    final response = await http.delete(
      Uri.parse(
        '$legalBaseUrl/image-annotations/$imageId/annotations/$annotationId/notes/$noteId',
      ),
      headers: {'apiKey': legalKey, 'user-email': email},
    );
    return response.statusCode == 200 || response.statusCode == 204;
  }

  // --- 9) DELETE ANNOTATION ---
  static Future<bool> deleteAnnotation({
    required String imageId,
    required String annotationId,
    required String email,
  }) async {
    final response = await http.delete(
      Uri.parse(
        '$legalBaseUrl/image-annotations/$imageId/annotations/$annotationId',
      ),
      headers: {'apiKey': legalKey, 'user-email': email},
    );
    return response.statusCode == 200 || response.statusCode == 204;
  }

  // --- 10) DELETE IMAGE RECORD ---
  static Future<bool> deleteImageRecord(String id, String email) async {
    final response = await http.delete(
      Uri.parse('$legalBaseUrl/image-annotations/$id'),
      headers: {'apiKey': legalKey, 'user-email': email},
    );
    return response.statusCode == 200 || response.statusCode == 204;
  }

  // --- 11) FETCH HISTORY ---
  static Future<List<dynamic>> fetchHistory(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$legalBaseUrl/image-annotations'),
        headers: {
          'apiKey': legalKey,
          'user-email': email,
          'Origin': 'https://cliniview.dfoundry.ai',
          'Referer': 'https://cliniview.dfoundry.ai/',
        },
      );
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data is List) return data;
        if (data is Map) {
          if (data.containsKey('images'))
            return data['images'] as List<dynamic>;
          if (data.containsKey('items')) return data['items'] as List<dynamic>;
          if (data.containsKey('data')) return data['data'] as List<dynamic>;
        }
      }
    } catch (e) {
      debugPrint('Fetch History Error: $e');
    }
    return [];
  }
}
