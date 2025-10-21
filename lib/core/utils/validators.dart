import '../constants/app_constants.dart';

class Validators {
  static bool isValidApiKey(String apiKey) {
    return apiKey.isNotEmpty && apiKey.length >= 20;
  }

  static bool isValidFileSize(int bytes) {
    return bytes <= AppConstants.maxFileSize;
  }

  static bool isValidFileExtension(String fileName) {
    return true;
  }

  Validators._();
}
