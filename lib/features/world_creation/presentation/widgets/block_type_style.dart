import 'package:flutter/material.dart';
import 'package:worlds/features/worlds/domain/content_block.dart';

extension BlockTypeStyle on BlockType {
  IconData get icon => switch (this) {
    BlockType.text => Icons.notes,
    BlockType.image => Icons.image_outlined,
    BlockType.storyChoice => Icons.call_split,
    BlockType.question => Icons.help_outline,
    BlockType.artwork => Icons.palette_outlined,
    BlockType.completion => Icons.flag_outlined,
  };
}

/// A one-line reminder of what a block says, for menus that refer to it.
String blockSummary(ContentBlock block) {
  final text = switch (block) {
    TextBlock(:final body) => body,
    ImageBlock(:final caption) => caption,
    StoryChoiceBlock(:final prompt) => prompt,
    QuestionBlock(:final prompt) => prompt,
    ArtworkBlock(:final title) => title,
    CompletionBlock(:final title) => title,
  }.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (text.isEmpty) return block.type.label;
  return text.length <= 40 ? text : '${text.substring(0, 39)}…';
}
