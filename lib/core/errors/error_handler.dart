import 'package:dio/dio.dart';
import '../utils/logger.dart';
import '../errors/app_exception.dart' as app_exceptions;

class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is app_exceptions.ValidationException) {
      return error.message;
    }

    if (error is app_exceptions.ApiException) {
      return error.message;
    }

    if (error is app_exceptions.NetworkException) {
      return error.message;
    }

    if (error is app_exceptions.TimeoutException) {
      return error.message;
    }

    if (error is app_exceptions.FileException) {
      return error.message;
    }

    if (error is DioException) {
      return _handleDioException(error);
    }

    if (error is app_exceptions.AppException) {
      return error.message;
    }

    return '알 수 없는 오류가 발생했습니다: ${error.toString()}';
  }

  static String _handleDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return '요청 시간이 초과되었습니다.\n네트워크 연결을 확인해주세요.';

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        return _getStatusMessage(statusCode, error.response?.data);

      case DioExceptionType.cancel:
        return '요청이 취소되었습니다.';

      case DioExceptionType.connectionError:
        return '네트워크 연결에 실패했습니다.\n인터넷 연결을 확인해주세요.';

      default:
        return '네트워크 오류: ${error.message}';
    }
  }

  static String _getStatusMessage(int? statusCode, dynamic responseData) {
    if (statusCode == null) return '서버 응답 오류';

    switch (statusCode) {
      case 400:
        String message = '요청이 잘못되었습니다.\n\n';

        if (responseData != null && responseData is Map) {
          final error = responseData['error'];
          if (error != null) {
            if (error is Map && error['message'] != null) {
              message += '상세: ${error['message']}\n\n';
            }
          }
        }

        message += '가능한 원인:\n'
            '• 첨부파일이 너무 큽니다 (모델 컨텍스트 한계 초과)\n'
            '• 메시지 형식이 올바르지 않습니다\n\n'
            '해결 방법:\n'
            '• 더 큰 컨텍스트 모델 사용\n'
            '  (Claude 3.5 Sonnet, Gemini Pro 1.5)\n'
            '• 첨부파일 크기 줄이기';
        return message;

      case 401:
        return 'API 키가 유효하지 않습니다.\n설정에서 API 키를 확인해주세요.';

      case 402:
        return '💳 크레딧 부족\n\n'
            'OpenRouter 계정에 크레딧이 부족합니다.\n\n'
            '해결 방법:\n'
            '• OpenRouter에서 크레딧 충전\n'
            '  (https://openrouter.ai/settings/credits)\n'
            '• 무료 모델로 변경 (설정 > 모델 선택)\n'
            '  예: DeepSeek R1 (무료), Llama 3.1 8B (무료)';

      case 403:
        return '접근이 거부되었습니다.\nAPI 키 권한을 확인해주세요.';

      case 429:
        String message = '⏱️ 요청 한도 초과\n\n';

        // Rate limit 상세 정보 추출
        if (responseData != null && responseData is Map) {
          final error = responseData['error'];
          if (error is Map) {
            final errorMessage = error['message'] as String?;
            if (errorMessage != null) {
              if (errorMessage.contains('rate-limited upstream')) {
                // 무료 모델 Rate Limit
                message += '무료 모델이 일시적으로 제한되었습니다.\n'
                    '많은 사용자가 동시에 사용하고 있습니다.\n\n'
                    '해결 방법:\n'
                    '1. 잠시 후 다시 시도 (30초~1분)\n'
                    '2. 다른 무료 모델로 변경\n'
                    '   • Llama 3.1 8B (무료)\n'
                    '   • Gemini Flash 1.5 (무료)\n'
                    '   • Mistral 7B (무료)\n'
                    '3. 크레딧 충전 후 유료 모델 사용';
              } else {
                // 일반 Rate Limit
                message += 'API 요청 한도를 초과했습니다.\n\n'
                    '해결 방법:\n'
                    '• 잠시 후 다시 시도해주세요\n'
                    '• API 키 플랜 확인\n'
                    '  (https://openrouter.ai/settings)';
              }
            }
          }
        } else {
          message += 'API 요청이 너무 많습니다.\n\n'
              '해결 방법:\n'
              '• 잠시 후 다시 시도해주세요\n'
              '• 무료 모델의 경우 대기 시간이 필요합니다';
        }

        return message;

      case 500:
      case 502:
      case 503:
        return '서버 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.';

      default:
        return '서버 오류 (코드: $statusCode)';
    }
  }

  static void logError(dynamic error, [StackTrace? stackTrace]) {
    Logger.error('Error occurred', error, stackTrace);
  }

  ErrorHandler._();
}
