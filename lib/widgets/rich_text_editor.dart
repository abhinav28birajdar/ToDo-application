import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class RichTextEditor extends StatefulWidget {
  final String? initialContent;
  final Function(String content) onContentChanged;
  final bool readOnly;
  final double? height;

  const RichTextEditor({
    super.key,
    this.initialContent,
    required this.onContentChanged,
    this.readOnly = false,
    this.height,
  });

  @override
  State<RichTextEditor> createState() => _RichTextEditorState();
}

class _RichTextEditorState extends State<RichTextEditor> {
  QuillController? _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    Document document = Document();
    
    if (widget.initialContent != null && widget.initialContent!.isNotEmpty) {
      try {
        // Try to parse as Delta JSON first
        final deltaJson = jsonDecode(widget.initialContent!) as List;
        document = Document.fromJson(deltaJson);
      } catch (e) {
        // If parsing fails, treat as plain text
        document = Document()..insert(0, widget.initialContent!);
      }
    }

    _controller = QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );

    _controller!.changes.listen((event) {
      final content = jsonEncode(_controller!.document.toDelta().toJson());
      widget.onContentChanged(content);
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (!widget.readOnly) _buildToolbar(theme),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              height: widget.height,
              child: QuillEditor.basic(
                controller: _controller!,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: QuillSimpleToolbar(
        controller: _controller!,
      ),
    );
  }
}

// Helper method to convert rich text to plain text for preview
String richTextToPlainText(String richTextContent) {
  try {
    final deltaJson = jsonDecode(richTextContent) as List;
    final document = Document.fromJson(deltaJson);
    return document.toPlainText();
  } catch (e) {
    return richTextContent;
  }
}

// Helper method to check if content is rich text
bool isRichTextContent(String content) {
  try {
    final decoded = jsonDecode(content);
    return decoded is List && decoded.isNotEmpty;
  } catch (e) {
    return false;
  }
}

// Simple rich text display widget for read-only content
class RichTextDisplay extends StatelessWidget {
  final String content;
  final TextStyle? baseStyle;

  const RichTextDisplay({
    super.key,
    required this.content,
    this.baseStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (!isRichTextContent(content)) {
      return Text(content, style: baseStyle);
    }

    try {
      final deltaJson = jsonDecode(content) as List;
      final document = Document.fromJson(deltaJson);
      
      return QuillEditor.basic(
        controller: QuillController(
          document: document,
          selection: const TextSelection.collapsed(offset: 0),
        ),
      );
    } catch (e) {
      return Text(content, style: baseStyle);
    }
  }
}