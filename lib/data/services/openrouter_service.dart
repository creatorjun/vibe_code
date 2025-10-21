// lib/data/services/openrouter_service.dart (전체 코드)
import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/logger.dart';
import '../models/api_request.dart';
import 'ai_service.dart';

class OpenRouterService implements AIService {
  final String apiKey;
  final Dio _dio;
  CancelToken? _cancelToken;

  OpenRouterService(this.apiKey)
      : _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: ApiConstants.connectTimeout,
    receiveTimeout: ApiConstants.receiveTimeout,
    headers: {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
      'HTTP-Referer': ApiConstants.httpReferer,
      'X-Title': ApiConstants.xTitle,
    },
  ));

  @override
  Stream<String> streamChat({
    required List<ChatMessage> messages,
    required String model,
  }) async* {
    _cancelToken = CancelToken();

    try {
      final requestBody = {
        'model': model,
        'messages': messages.map((m) => m.toJson()).toList(),
        'stream': true,
      };

      Logger.info('Starting streaming chat: model=$model');

      final response = await _dio.post<ResponseBody>(
        ApiConstants.chatEndpoint,
        data: requestBody,
        options: Options(
          responseType: ResponseType.stream,
          validateStatus: (status) => status != null && status < 500,
        ),
        cancelToken: _cancelToken,
      );

      if (response.statusCode != 200) {
        final errorBytes = await response.data?.stream.toList();
        final errorData = errorBytes != null
            ? utf8.decode(errorBytes.expand((x) => x).toList())
            : '';
        Logger.error('API error: ${response.statusCode} - $errorData');
        throw ApiException(
          'API 요청 실패: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }

      await for (final chunk in response.data!.stream) {
        final text = utf8.decode(chunk);
        final lines = text.split('\n').where((line) => line.isNotEmpty);

        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6);
            if (data == '[DONE]') continue;

            try {
              final json = jsonDecode(data);
              final content = json['choices']?[0]?['delta']?['content'];
              if (content != null && content is String) {
                yield content;
              }
            } catch (e) {
              Logger.warning('Failed to parse chunk: $data');
            }
          }
        }
      }

      Logger.info('Streaming completed successfully');
    } on DioException catch (e) {
      Logger.error('Dio error during streaming', e);
      if (e.type == DioExceptionType.cancel) {
        throw const NetworkException('요청이 취소되었습니다');
      }
      throw NetworkException('네트워크 오류: ${e.message}');
    } catch (e, stackTrace) {
      Logger.error('Unexpected error during streaming', e, stackTrace);
      rethrow;
    }
  }

  /// 스트리밍 취소
  void cancelStreaming() {
    _cancelToken?.cancel('User cancelled streaming');
    Logger.info('Streaming cancelled by user');
  }

  @override
  void dispose() {
    _cancelToken?.cancel('Service disposed');
    _dio.close();
    Logger.info('OpenRouterService disposed');
  }
}
