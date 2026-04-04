extension StringX on String? {
  bool get isNullOrBlank => this == null || this!.trim().isEmpty;
}
