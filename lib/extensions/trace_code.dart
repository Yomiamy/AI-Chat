import 'dart:developer';

extension TraceCode<T> on T Function() {
  T traceCode(String name) {
    Timeline.startSync(name);
    try {
      return this();
    } finally {
      Timeline.finishSync();
    }
  }
}

extension TraceCodeAsync<T> on Future<T> Function() {
  Future<T> traceCodeAsync(String name) async {
    final task = TimelineTask();
    task.start(name);
    try {
      return await this();
    } finally {
      task.finish();
    }
  }
}
