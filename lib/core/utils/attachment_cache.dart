// lib/core/utils/attachment_cache.dart

import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';

/// 첨부 파일 캐시 관리 클래스 (싱글톤)
class AttachmentCache {
  static final AttachmentCache _instance = AttachmentCache._internal();

  factory AttachmentCache() => _instance;

  AttachmentCache._internal();

  // 이미지 Base64 캐시 (LRU)
  final Map<String, String> _imageCache = {};

  // 텍스트 파일 내용 캐시
  final Map<String, String> _textCache = {};

  /// 캐시된 이미지 조회
  String? getCachedImage(String attachmentId) {
    final cached = _imageCache[attachmentId];
    if (cached != null) {
      Logger.debug('Image cache hit: $attachmentId');
    }
    return cached;
  }

  /// 이미지 캐시에 저장 (LRU 방식)
  void cacheImage(String attachmentId, String base64Data) {
    if (_imageCache.length >= AppConstants.maxCachedAttachments) {
      // 가장 오래된 항목 제거 (LRU)
      final oldestKey = _imageCache.keys.first;
      _imageCache.remove(oldestKey);
      Logger.debug('Image cache evicted: $oldestKey');
    }

    _imageCache[attachmentId] = base64Data;
    Logger.debug('Image cached: $attachmentId (${base64Data.length} chars)');
  }

  /// 캐시된 텍스트 조회
  String? getCachedText(String attachmentId) {
    final cached = _textCache[attachmentId];
    if (cached != null) {
      Logger.debug('Text cache hit: $attachmentId');
    }
    return cached;
  }

  /// 텍스트 캐시에 저장
  void cacheText(String attachmentId, String content) {
    if (_textCache.length >= AppConstants.maxCachedAttachments) {
      final oldestKey = _textCache.keys.first;
      _textCache.remove(oldestKey);
      Logger.debug('Text cache evicted: $oldestKey');
    }

    _textCache[attachmentId] = content;
    Logger.debug('Text cached: $attachmentId (${content.length} chars)');
  }

  /// 특정 첨부파일 캐시 제거
  void remove(String attachmentId) {
    _imageCache.remove(attachmentId);
    _textCache.remove(attachmentId);
    Logger.debug('Cache removed: $attachmentId');
  }

  /// 전체 캐시 초기화
  void clear() {
    final imageCount = _imageCache.length;
    final textCount = _textCache.length;

    _imageCache.clear();
    _textCache.clear();

    Logger.info('Cache cleared: $imageCount images, $textCount texts');
  }

  /// 캐시 통계
  Map<String, int> getStats() {
    return {
      'images': _imageCache.length,
      'texts': _textCache.length,
      'total': _imageCache.length + _textCache.length,
    };
  }
}
