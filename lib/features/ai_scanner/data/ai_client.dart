import 'dart:io';

abstract class AiClient {
  Future<Map<String, dynamic>> parseReceipt(
    File imageFile, {
    List<String> defaultCategoryKeys = const <String>[],
    List<String> customCategoryNames = const <String>[],
  });
}
