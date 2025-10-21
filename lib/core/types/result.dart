// lib/core/types/result.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../errors/app_exception.dart';

part 'result.freezed.dart';

@freezed
sealed class Result<T> with _$Result<T> {
  const Result._();

  const factory Result.success(T data) = Success<T>;
  const factory Result.failure(AppException error) = Failure<T>;

  /// 성공 여부 확인
  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  /// 데이터 또는 에러 추출
  T? get dataOrNull => switch (this) {
    Success(:final data) => data,
    Failure() => null,
  };

  AppException? get errorOrNull => switch (this) {
    Success() => null,
    Failure(:final error) => error,
  };

  /// 값을 변환
  Result<R> map<R>(R Function(T data) transform) {
    return switch (this) {
      Success(:final data) => Result.success(transform(data)),
      Failure(:final error) => Result.failure(error),
    };
  }

  /// 값을 가져오거나 예외 throw
  T getOrThrow() {
    return switch (this) {
      Success(:final data) => data,
      Failure(:final error) => throw error,
    };
  }

  /// 값을 가져오거나 기본값 반환
  T getOrElse(T Function() defaultValue) {
    return switch (this) {
      Success(:final data) => data,
      Failure() => defaultValue(),
    };
  }
}
