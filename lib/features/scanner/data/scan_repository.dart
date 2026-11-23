import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import 'package:kawangizi_mobile/core/network/api_client.dart';

class ScanRepository {
  ScanRepository({required ApiClient api}) : _api = api;

  final ApiClient _api;

  Future<Map<String, dynamic>> upload({
    required XFile image,
    required String qrToken,
    required double holdingTempC,
    required double releaseTempC,
  }) async {
    final form = FormData.fromMap({
      'image': await MultipartFile.fromFile(
        image.path,
        filename: image.name.isEmpty ? 'scan.jpg' : image.name,
      ),
      'qrToken': qrToken.trim(),
      'holdingTempC': holdingTempC.toString(),
      'releaseTempC': releaseTempC.toString(),
    });
    final response = await _api.postForm('/api/scans', form);
    final body = response.data;
    if (body is Map && body['success'] == true && body['data'] is Map) {
      return Map<String, dynamic>.from(body['data'] as Map);
    }
    throw ApiException(
      body is Map
          ? (body['error'] ?? body['message'] ?? 'Pemindaian gagal.').toString()
          : 'Pemindaian gagal.',
    );
  }
}
