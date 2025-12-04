import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Import to check platform

class CloudinaryService {
  final String cloudName = "dhgednrce";
  final String uploadPreset = "elearning_preset";

  // File picker function (Web compatible)
  Future<PlatformFile?> pickFile({FileType type = FileType.any}) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: type,
        allowMultiple: false,
        withData: true, // <--- REQUIRED FOR WEB (To get bytes)
      );
      return result?.files.first;
    } catch (e) {
      return null;
    }
  }

  // File upload function (Cross-platform compatible)
  Future<String?> uploadFile(PlatformFile platformFile) async {
    try {
      final uri = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/auto/upload");
      final request = http.MultipartRequest("POST", uri);

      // --- HANDLING DIFFERENCES BETWEEN WEB AND MOBILE ---
      if (kIsWeb) {
        // On Web: Use bytes
        if (platformFile.bytes == null) {
          return null;
        }
        request.files.add(
            http.MultipartFile.fromBytes(
                'file',
                platformFile.bytes!,
                filename: platformFile.name
            )
        );
      } else {
        // On Mobile/Desktop: Use path
        if (platformFile.path == null) {
          return null;
        }
        request.files.add(await http.MultipartFile.fromPath('file', platformFile.path!));
      }
      // ------------------------------------------

      request.fields['upload_preset'] = uploadPreset;
      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);

      if (response.statusCode == 200) {
        final jsonMap = jsonDecode(responseString);
        return jsonMap['secure_url'];
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}