import 'package:flutter/material.dart';

class SearchAppBar extends StatefulWidget implements PreferredSizeWidget {
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
  State<SearchAppBar> createState() => _SearchAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _SearchAppBarState extends State<SearchAppBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(SearchAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != _controller.text) {
      _controller.text = widget.query;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: widget.onBack,
      ),
      title: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: widget.hintText,
          border: InputBorder.none,
          hintStyle: const TextStyle(color: Colors.grey),
        ),
        style: const TextStyle(fontSize: 18),
        onChanged: widget.onQueryChanged,
      ),
      actions: [
        if (widget.query.isNotEmpty)
          IconButton(icon: const Icon(Icons.clear), onPressed: widget.onClear),
      ],
    );
  }
}
