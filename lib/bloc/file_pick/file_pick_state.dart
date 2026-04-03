part of 'file_pick_bloc.dart';

class FilePickState {
  final Status? status;
  final LinkedHashMap<String, Uint8List>? selectedFileBtypesMap;

  const FilePickState({
    this.status = Status.initial,
    this.selectedFileBtypesMap,
  });

  FilePickState copyWith({Status? status, LinkedHashMap<String, Uint8List>? selectedFileBtypesMap}) {
    return FilePickState(
      status: status ?? this.status,
      selectedFileBtypesMap: selectedFileBtypesMap ?? this.selectedFileBtypesMap,
    );
  }
}
