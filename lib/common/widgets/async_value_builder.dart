import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// AsyncValue의 loading/error/data를 공통 패턴으로 렌더링
///
/// - loading: 기본 CircularProgressIndicator (custom 가능)
/// - error: 기본 Text (custom 가능)
/// - data: 필수 builder
class AsyncValueBuilder<T> extends StatelessWidget {
  const AsyncValueBuilder({
    super.key,
    required this.value,
    required this.data,
    this.loading,
    this.error,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget? loading;
  final Widget Function(Object error, StackTrace? stackTrace)? error;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () =>
          loading ?? const Center(child: CircularProgressIndicator()),
      error: (e, st) => error != null
          ? error!(e, st)
          : Center(child: Text('Error: $e')),
      data: data,
    );
  }
}
