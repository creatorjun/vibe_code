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
    Function(int inputTokens, int outputTokens)? onTokenUsage,
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
          // JSON 파싱 실패 시 원본 사용
        }

        // Dio 에러 로깅
        Logger.error('API error: ${response.statusCode} - $errorData');

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

      // JSON 라인 버퍼
      String lineBuffer = '';

      await for (final chunk in response.data!.stream) {
        final text = utf8.decode(chunk);
        lineBuffer += text;

        final lines = lineBuffer.split('\n');
        lineBuffer = lines.isNotEmpty ? lines.last : '';

        for (var i = 0; i < lines.length - 1; i++) {
          final line = lines[i].trim();
          if (line.isEmpty) continue;

          if (line.startsWith('data:')) {
            final data = line.substring(6);
            if (data == '[DONE]') continue;

            try {
              final json = jsonDecode(data);
              final content = json['choices']?[0]?['delta']?['content'];
              if (content != null && content is String) {
                yield content;
              }

              // ✅ 토큰 사용량 추출
              final usage = json['usage'];
              if (usage != null && onTokenUsage != null) {
                final inputTokens = usage['prompt_tokens'] ?? 0;
                final outputTokens = usage['completion_tokens'] ?? 0;
                onTokenUsage(inputTokens, outputTokens);
                Logger.info('💰 Actual tokens: input=$inputTokens, output=$outputTokens');
              }
            } catch (e) {
              // JSON 파싱 실패 시 무시
              Logger.debug('Skipping incomplete chunk: ${data.length > 100 ? data.substring(0, 100) : data}...');
              continue;
            }
          }
        }
      }

      // 버퍼에 남은 데이터 처리
      if (lineBuffer.isNotEmpty) {
        final line = lineBuffer.trim();
        if (line.startsWith('data:')) {
          final data = line.substring(6);
          if (data != '[DONE]') {
            try {
              final json = jsonDecode(data);
              final content = json['choices']?[0]?['delta']?['content'];
              if (content != null && content is String) {
                yield content;
              }

              // ✅ 토큰 사용량 추출
              final usage = json['usage'];
              if (usage != null && onTokenUsage != null) {
                final inputTokens = usage['prompt_tokens'] ?? 0;
                final outputTokens = usage['completion_tokens'] ?? 0;
                onTokenUsage(inputTokens, outputTokens);
                Logger.info('💰 Actual tokens: input=$inputTokens, output=$outputTokens');
              }
            } catch (e) {
              Logger.debug('Skipping final incomplete chunk');
            }
          }
        }
      }

      Logger.info('Streaming completed successfully');
    } on DioException catch (e) {
      Logger.error('Dio error during streaming', e);
      rethrow;
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
