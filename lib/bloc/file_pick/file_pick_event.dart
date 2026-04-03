part of 'file_pick_bloc.dart';

abstract class FilePickEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FilePickInitEvent extends FilePickEvent {}

class FilePickPickFileEvent extends FilePickEvent {}

class FilePickPickImageEvent extends FilePickEvent {}
