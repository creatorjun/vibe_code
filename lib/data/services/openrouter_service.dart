import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/logger.dart';
import '../models/api_request.dart';
import '../models/api_response.dart';

class OpenRouterService {
  final String apiKey;
  final Dio _dio;
  CancelToken? _cancelToken;

  OpenRouterService(this.apiKey)
      : _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        ApiConstants.headerContentType: ApiConstants.contentTypeJson,
        ApiConstants.headerHttpReferer: 'https://github.com/creatorjun/vibe_code',
        ApiConstants.headerXTitle: 'Vibe Code',
      },
    ),
  );

  Stream<String> streamChat({
    required List<ChatMessage> messages,
    required String model,
    double temperature = 0.7,
    int maxTokens = 4096,
  }) async* {
    _cancelToken = CancelToken();

    final request = ChatRequest(
      model: model,
      messages: messages,
      stream: true,
      temperature: temperature,
      maxTokens: maxTokens,
    );

    Logger.info('Streaming chat request - Model: $model, Messages: ${messages.length}');

    try {
      final response = await _dio.post<ResponseBody>(
        ApiConstants.chatCompletionsEndpoint,
        data: request.toJson(),
        options: Options(
          headers: {
            ApiConstants.headerAuthorization: 'Bearer $apiKey',
          },
          responseType: ResponseType.stream,
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
        ),
        cancelToken: _cancelToken,
      );

      if (response.data == null) {
        throw const ApiException('응답 데이터가 없습니다.');
      }

      final stream = response.data!.stream;
      final buffer = StringBuffer();

      await for (final chunk in stream.timeout(
        const Duration(seconds: 30),
        onTimeout: (sink) {
          Logger.warning('Stream timeout - no data received for 30 seconds');
          sink.close();
        },
      )) {
        if (_cancelToken?.isCancelled ?? false) {
          Logger.info('Stream cancelled by user');
          break;
        }

        final text = utf8.decode(chunk);
        buffer.write(text);

        final lines = buffer.toString().split('\n');

        if (lines.isNotEmpty) {
          buffer.clear();
          buffer.write(lines.last);

          for (var i = 0; i < lines.length - 1; i++) {
            final line = lines[i].trim();

            if (line.isEmpty || line == 'data: [DONE]') continue;
            if (!line.startsWith('data: ')) continue;

            final jsonStr = line.substring(6);

            try {
              final json = jsonDecode(jsonStr) as Map<String, dynamic>;
              final streamResponse = ChatStreamResponse.fromJson(json);

              if (streamResponse.choices.isNotEmpty) {
                final delta = streamResponse.choices.first.delta;
                if (delta.content != null && delta.content!.isNotEmpty) {
                  yield delta.content!;
                }
              }
            } catch (e) {
              Logger.warning('Failed to parse streaming chunk: $e');
            }
          }
        }
      }

      Logger.info('Streaming completed successfully');
    } on TimeoutException {
      Logger.error('Stream timeout', 'No response within timeout period', null);
      throw const TimeoutException('응답 시간 초과: 서버가 응답하지 않습니다.');
    } on DioException catch (e, stackTrace) {
      Logger.error('Dio error during streaming', e, stackTrace);
      throw _handleDioException(e);
    } catch (e, stackTrace) {
      Logger.error('Unexpected error during streaming', e, stackTrace);
      throw ApiException('스트리밍 중 오류가 발생했습니다: $e');
    }
  }

  Future<ChatResponse> sendChat({
    required List<ChatMessage> messages,
    required String model,
    double temperature = 0.7,
    int maxTokens = 4096,
  }) async {
    final request = ChatRequest(
      model: model,
      messages: messages,
      stream: false,
      temperature: temperature,
      maxTokens: maxTokens,
    );

    Logger.info('Sending chat request - Model: $model, Messages: ${messages.length}');

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.chatCompletionsEndpoint,
        data: request.toJson(),
        options: Options(
          headers: {
            ApiConstants.headerAuthorization: 'Bearer $apiKey',
          },
        ),
      );

      if (response.data == null) {
        throw const ApiException('응답 데이터가 없습니다.');
      }

      Logger.info('Chat request completed successfully');
      return ChatResponse.fromJson(response.data!);
    } on DioException catch (e, stackTrace) {
      Logger.error('Dio error during chat', e, stackTrace);
      throw _handleDioException(e);
    } catch (e, stackTrace) {
      Logger.error('Unexpected error during chat', e, stackTrace);
      throw ApiException('채팅 요청 중 오류가 발생했습니다: $e');
    }
  }

  void cancelStreaming() {
    _cancelToken?.cancel('사용자가 스트리밍을 취소했습니다.');
    Logger.info('Streaming cancellation requested');
  }

  AppException _handleDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException('요청 시간이 초과되었습니다.');

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        return ApiException(_getStatusMessage(statusCode), statusCode: statusCode);

      case DioExceptionType.cancel:
        return const ApiException('요청이 취소되었습니다.');

      case DioExceptionType.connectionError:
        return const NetworkException('네트워크 연결에 실패했습니다.');

      default:
        return NetworkException('네트워크 오류: ${error.message}');
    }
  }

  String _getStatusMessage(int? statusCode) {
    if (statusCode == null) return '서버 응답 오류';

    switch (statusCode) {
      case 400:
        return '요청이 잘못되었습니다.\n\n'
            '가능한 원인:\n'
            '• 첨부파일이 너무 큽니다 (현재 모델의 컨텍스트 한계 초과)\n'
            '• 메시지 형식이 올바르지 않습니다\n\n'
            '해결 방법:\n'
            '• 더 큰 컨텍스트를 지원하는 모델로 변경하세요\n'
            '  (Claude 3.5 Sonnet, Gemini Pro 1.5 등)\n'
            '• 첨부파일 크기를 줄이거나 분할하세요';
      case 401:
        return 'API 키가 유효하지 않습니다.\n설정에서 API 키를 확인해주세요.';
      case 402:
        return '크레딧이 부족합니다.\nOpenRouter 계정에 크레딧을 충전해주세요.';
      case 403:
        return '접근이 거부되었습니다.\nAPI 키 권한을 확인해주세요.';
      case 429:
        return '요청 한도를 초과했습니다.\n잠시 후 다시 시도해주세요.';
      case 500:
      case 502:
      case 503:
        return '서버 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.';
      default:
        return '서버 오류 (코드: $statusCode)';
    }
  }


  void dispose() {
    _cancelToken?.cancel();
    _dio.close();
  }
}
