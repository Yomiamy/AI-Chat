import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/features.dart';
import '../status.dart';

part 'file_pick_event.dart';
part 'file_pick_state.dart';

class FilePickBloc extends Bloc<FilePickEvent, FilePickState> {
  FilePickBloc() : super(const FilePickState()) {
    on<FilePickInitEvent>(_init);
    on<FilePickPickFileEvent>(_pickFile);
    on<FilePickPickImageEvent>(_pickImage);
  }

  FutureOr<void> _init(
    FilePickInitEvent event,
    Emitter<FilePickState> emit,
  ) async {
    emit(const FilePickState());
  }

  FutureOr<void> _pickFile(
    FilePickPickFileEvent event,
    Emitter<FilePickState> emit,
  ) async {
    emit(state.copyWith(status: Status.loading));

    final result = await PermissionManager.pickFile();
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    Uint8List? bytes = file.bytes;

    if (bytes == null && file.path != null) {
      bytes = await File(file.path!).readAsBytes();
    }

    if (bytes == null) return;

    final ext = file.extension?.toLowerCase() ?? '';
    final mime = switch (ext) {
      'pdf' => 'application/pdf',
      'txt' => 'text/plain',
      'csv' => 'text/csv',
      'doc' || 'docx' => 'application/msword',
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'application/octet-stream',
    };

    emit(state.copyWith(status: Status.success));
  }

  FutureOr<void> _pickImage(
    FilePickPickImageEvent event,
    Emitter<FilePickState> emit,
  ) async {
    emit(state.copyWith(status: Status.loading));
  } 
}
