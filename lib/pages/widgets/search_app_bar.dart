import 'package:flutter/material.dart';

class SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String query;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onBack;
  final VoidCallback onClear;
  final String hintText;

  const SearchAppBar({
    super.key,
    required this.query,
    required this.onQueryChanged,
    required this.onBack,
    required this.onClear,
    this.hintText = 'Search...',
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onBack,
      ),
      title: TextField(
        autofocus: true,
        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
          hintStyle: const TextStyle(color: Colors.grey),
        ),
        style: const TextStyle(fontSize: 18),
        onChanged: onQueryChanged,
        controller: TextEditingController.fromValue(
          TextEditingValue(
            text: query,
            selection: TextSelection.collapsed(offset: query.length),
          ),
        ),
      ),
      actions: [
        if (query.isNotEmpty)
          IconButton(icon: const Icon(Icons.clear), onPressed: onClear),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
