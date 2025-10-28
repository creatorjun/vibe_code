// lib/data/services/openrouter_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
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
    Function(int inputTokens, int outputTokens)? onTokenUsage, // ===== 추가 =====
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

      // 에러 응답 처리
      if (response.statusCode != 200) {
        final errorBytes = await response.data?.stream.toList();
        final errorData = errorBytes != null
            ? utf8.decode(errorBytes.expand((x) => x).toList())
            : '';

        // JSON 파싱 시도
        dynamic errorJson;
        try {
          errorJson = jsonDecode(errorData);
        } catch (e) {
      if (e is DioException) {
        // 추가: 상세 에러 정보 출력
        Logger.error('DioException Details:', e);
        Logger.error('Status Code: ${e.response?.statusCode}');
        Logger.error('Response Data: ${e.response?.data}');
        Logger.error('Error Message: ${e.message}');
        Logger.error('Error Type: ${e.type}');
      }
      Logger.error('Dio error during streaming', e);
      rethrow;
    }

        Logger.error('API error: ${response.statusCode} - $errorData');

        // DioException으로 던지기 (ErrorHandler가 처리하도록)
        throw DioException(
          requestOptions: response.requestOptions,
          response: Response(
            requestOptions: response.requestOptions,
            statusCode: response.statusCode,
            data: errorJson,
          ),
          type: DioExceptionType.badResponse,
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

              // ===== 추가: 토큰 사용량 추출 =====
              final usage = json['usage'];
              if (usage != null && onTokenUsage != null) {
                final inputTokens = usage['prompt_tokens'] ?? 0;
                final outputTokens = usage['completion_tokens'] ?? 0;
                onTokenUsage(inputTokens, outputTokens);
              }
              // ====================================
            } catch (e) {
              Logger.warning('Failed to parse chunk: $data');
            }
          }
        }
      }

      Logger.info('Streaming completed successfully');
    } on DioException catch (e) {
      Logger.error('Dio error during streaming', e);
      rethrow; // ErrorHandler가 처리하도록
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
