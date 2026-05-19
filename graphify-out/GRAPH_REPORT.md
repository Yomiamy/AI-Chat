# Graph Report - lib  (2026-05-19)

## Corpus Check
- Corpus is ~9,678 words - fits in a single context window. You may not need a graph.

## Summary
- 296 nodes · 321 edges · 28 communities (25 shown, 3 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Localization (intl messages)|Localization (intl messages)]]
- [[_COMMUNITY_Chat UI Widgets|Chat UI Widgets]]
- [[_COMMUNITY_Message Bubble & Styling|Message Bubble & Styling]]
- [[_COMMUNITY_ObjectBox Data Layer|ObjectBox Data Layer]]
- [[_COMMUNITY_BLoC State Management|BLoC State Management]]
- [[_COMMUNITY_Generated Assets & l10n|Generated Assets & l10n]]
- [[_COMMUNITY_File  Image Picker|File / Image Picker]]
- [[_COMMUNITY_Export Service|Export Service]]
- [[_COMMUNITY_ObjectBox Model Schema|ObjectBox Model Schema]]
- [[_COMMUNITY_App Bootstrap & DI|App Bootstrap & DI]]
- [[_COMMUNITY_Page Composition & Injection|Page Composition & Injection]]
- [[_COMMUNITY_Gemini API Events|Gemini API Events]]
- [[_COMMUNITY_Search App Bar|Search App Bar]]
- [[_COMMUNITY_Highlight Text Widget|Highlight Text Widget]]
- [[_COMMUNITY_Chat Entry Prefix|Chat Entry Prefix]]
- [[_COMMUNITY_Search Events|Search Events]]
- [[_COMMUNITY_Gemini API State|Gemini API State]]
- [[_COMMUNITY_Search State|Search State]]
- [[_COMMUNITY_App Constants|App Constants]]

## God Nodes (most connected - your core abstractions)
1. `../generated/l10n.dart` - 17 edges
2. `package:flutter/material.dart` - 16 edges
3. `../generated/objectbox/objectbox.g.dart` - 9 edges
4. `package:intl/intl.dart` - 8 edges
5. `../../data/chat_message.dart` - 8 edges
6. `../../data/chat_repository.dart` - 8 edges
7. `../../features/foundation/style/sizes.dart` - 7 edges
8. `../features/utils/widget_preview.dart` - 7 edges
9. `package:ai_chat/generated/assets/colors.gen.dart` - 6 edges
10. `dart:async` - 4 edges

## Surprising Connections (you probably didn't know these)
- `../generated/l10n.dart` --defines--> `S`  [EXTRACTED]
  services/export_service.dart → generated/l10n.dart
- `../generated/l10n.dart` --defines--> `AppLocalizationDelegate`  [EXTRACTED]
  services/export_service.dart → generated/l10n.dart
- `../generated/l10n.dart` --defines--> `initializeMessages`  [EXTRACTED]
  services/export_service.dart → generated/l10n.dart
- `../generated/l10n.dart` --defines--> `of`  [EXTRACTED]
  services/export_service.dart → generated/l10n.dart
- `../generated/l10n.dart` --defines--> `aboutDialogVersion`  [EXTRACTED]
  services/export_service.dart → generated/l10n.dart

## Communities (28 total, 3 thin omitted)

### Community 0 - "Localization (intl messages)"
Cohesion: 0.06
Nodes (30): l10n.dart, messages_en.dart, messages_zh.dart, messages_zh_TW.dart, package:flutter/foundation.dart, package:intl/intl.dart, package:intl/message_lookup_by_library.dart, package:intl/src/intl_helpers.dart (+22 more)

### Community 1 - "Chat UI Widgets"
Cohesion: 0.06
Nodes (30): empty_widget.dart, ../../features/features.dart, input_area_widget.dart, loading_indicator_widget.dart, message_bubble_widget.dart, search_app_bar.dart, search_result_item.dart, AiChatView (+22 more)

### Community 2 - "Message Bubble & Styling"
Cohesion: 0.08
Nodes (24): dart:convert, ../../features/foundation/style/sizes.dart, package:ai_chat/generated/assets/colors.gen.dart, package:flutter_markdown/flutter_markdown.dart, package:flutter/material.dart, package:flutter/painting.dart, package:url_launcher/url_launcher.dart, appBar (+16 more)

### Community 3 - "ObjectBox Data Layer"
Cohesion: 0.08
Nodes (24): chat_message.dart, dart:typed_data, ../../data/chat_message.dart, ../../data/chat_repository.dart, ../generated/objectbox/objectbox.g.dart, highlight_text.dart, package:collection/collection.dart, package:flat_buffers/flat_buffers.dart (+16 more)

### Community 4 - "BLoC State Management"
Cohesion: 0.09
Nodes (22): dart:async, models/models.dart, package:ai_chat/data/data.dart, package:ai_chat/features/features.dart, package:bloc/bloc.dart, package:equatable/equatable.dart, package:firebase_ai/firebase_ai.dart, package:flutter_bloc/flutter_bloc.dart (+14 more)

### Community 5 - "Generated Assets & l10n"
Cohesion: 0.09
Nodes (20): l10n_en.dart, l10n_zh.dart, package:flutter/widgets.dart, AssetGenImage, AssetGenImageAnimation, AssetImage, Assets, image (+12 more)

### Community 6 - "File / Image Picker"
Cohesion: 0.10
Nodes (18): package:ai_chat/bloc/bloc.dart, package:file_picker/file_picker.dart, package:flutter/services.dart, package:image_picker/image_picker.dart, package:permission_handler/permission_handler.dart, FilePickManager, build, Container (+10 more)

### Community 7 - "Export Service"
Cohesion: 0.11
Nodes (17): dart:io, ../generated/l10n.dart, intl/messages_all.dart, package:path_provider/path_provider.dart, package:share_plus/share_plus.dart, aboutDialogModel, aboutDialogVersion, AppLocalizationDelegate (+9 more)

### Community 8 - "ObjectBox Model Schema"
Cohesion: 0.12
Nodes (15): entities, lastEntityId, lastIndexId, lastRelationId, lastSequenceId, modelVersion, modelVersionParserMinimum, _note1 (+7 more)

### Community 9 - "App Bootstrap & DI"
Cohesion: 0.12
Nodes (14): dart:ui, ../features/utils/widget_preview.dart, package:ai_chat/generated/l10n.dart, package:ai_chat/pages/ai_chat_page.dart, package:firebase_core/firebase_core.dart, package:flutter_localizations/flutter_localizations.dart, package:flutter/widget_previews.dart, DevicePreviewAll (+6 more)

### Community 10 - "Page Composition & Injection"
Cohesion: 0.22
Nodes (7): ../../data/data.dart, package:get_it/get_it.dart, AiChatPage, build, MultiBlocProvider, previewPage, widgets/ai_chat_view.dart

### Community 11 - "Gemini API Events"
Cohesion: 0.22
Nodes (8): GeminiApiClearAllEvent, GeminiApiEvent, GeminiApiInitEvent, GeminiApiNewChatEvent, GeminiApiPickFileEvent, GeminiApiPickImageEvent, GeminiApiQueryEvent, GeminiApiRemoveFileEvent

### Community 12 - "Search App Bar"
Cohesion: 0.25
Nodes (7): AppBar, build, didUpdateWidget, dispose, initState, SearchAppBar, _SearchAppBarState

### Community 13 - "Highlight Text Widget"
Cohesion: 0.40
Nodes (4): build, HighlightText, RichText, Text

### Community 14 - "Chat Entry Prefix"
Cohesion: 0.40
Nodes (4): ChatEntryPrefix, matches, strip, wrap

### Community 15 - "Search Events"
Cohesion: 0.50
Nodes (3): SearchCleared, SearchEvent, SearchQueryChanged

## Knowledge Gaps
- **226 isolated node(s):** `MyApp`, `_initLocale`, `configureDependencies`, `build`, `MaterialApp` (+221 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **3 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `package:flutter/material.dart` connect `Message Bubble & Styling` to `Chat UI Widgets`, `ObjectBox Data Layer`, `BLoC State Management`, `File / Image Picker`, `Export Service`, `App Bootstrap & DI`, `Page Composition & Injection`, `Search App Bar`, `Highlight Text Widget`?**
  _High betweenness centrality (0.251) - this node is a cross-community bridge._
- **Why does `../generated/l10n.dart` connect `Export Service` to `Localization (intl messages)`, `Chat UI Widgets`, `Message Bubble & Styling`, `File / Image Picker`, `App Bootstrap & DI`?**
  _High betweenness centrality (0.223) - this node is a cross-community bridge._
- **Why does `package:intl/intl.dart` connect `Localization (intl messages)` to `Generated Assets & l10n`, `Export Service`?**
  _High betweenness centrality (0.198) - this node is a cross-community bridge._
- **What connects `MyApp`, `_initLocale`, `configureDependencies` to the rest of the system?**
  _226 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Localization (intl messages)` be split into smaller, more focused modules?**
  _Cohesion score 0.06190476190476191 - nodes in this community are weakly interconnected._
- **Should `Chat UI Widgets` be split into smaller, more focused modules?**
  _Cohesion score 0.06451612903225806 - nodes in this community are weakly interconnected._
- **Should `Message Bubble & Styling` be split into smaller, more focused modules?**
  _Cohesion score 0.0812807881773399 - nodes in this community are weakly interconnected._