import 'package:worlds/features/worlds/domain/content_block.dart';

/// Converts content blocks to and from the JSON the database functions use.
/// Each type writes exactly the keys the server accepts; there is no way to
/// put an answer inside a block. Shared by the creator and the player.
abstract final class ContentBlockCodec {
  static Map<String, Object?> toJson(ContentBlock block) => {
    'id': block.id,
    'block_type': block.type.wire,
    'content': switch (block) {
      TextBlock(:final body) => {'body': body},
      ImageBlock(:final assetId, :final caption) => {
        'asset_id': assetId,
        'caption': _nullIfBlank(caption),
      },
      StoryChoiceBlock(:final prompt, :final options) => {
        'prompt': prompt,
        'options': [
          for (final option in options)
            {
              'id': option.id,
              'label': option.label,
              'destination_block_id': option.destinationBlockId,
            },
        ],
      },
      QuestionBlock(:final prompt, :final hint, :final successMessage) => {
        'prompt': prompt,
        'hint': _nullIfBlank(hint),
        'success_message': _nullIfBlank(successMessage),
      },
      ArtworkBlock(:final assetId, :final title, :final description) => {
        'asset_id': assetId,
        'title': title,
        'description': description,
      },
      CompletionBlock(:final title, :final message, :final assetId) => {
        'title': title,
        'message': message,
        'asset_id': assetId,
      },
    },
  };

  static ContentBlock fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final content = json['content'] as Map<String, dynamic>? ?? const {};
    String text(String key) => content[key] as String? ?? '';
    String? optionalId(String key) => content[key] as String?;

    final type = BlockType.fromWire(json['block_type'] as String? ?? '');
    return switch (type) {
      BlockType.text => ContentBlock.text(id: id, body: text('body')),
      BlockType.image => ContentBlock.image(
        id: id,
        assetId: optionalId('asset_id'),
        caption: text('caption'),
      ),
      BlockType.storyChoice => ContentBlock.storyChoice(
        id: id,
        prompt: text('prompt'),
        options: [
          for (final option in content['options'] as List<dynamic>? ?? const [])
            StoryOption(
              id: (option as Map<String, dynamic>)['id'] as String,
              label: option['label'] as String? ?? '',
              destinationBlockId: option['destination_block_id'] as String?,
            ),
        ],
      ),
      BlockType.question => ContentBlock.question(
        id: id,
        prompt: text('prompt'),
        hint: text('hint'),
        successMessage: text('success_message'),
        hasAnswer: json['has_answer'] as bool? ?? false,
      ),
      BlockType.artwork => ContentBlock.artwork(
        id: id,
        assetId: optionalId('asset_id'),
        title: text('title'),
        description: text('description'),
      ),
      BlockType.completion => ContentBlock.completion(
        id: id,
        title: text('title'),
        message: text('message'),
        assetId: optionalId('asset_id'),
      ),
      null => throw FormatException('Unknown block type in block $id'),
    };
  }

  static String? _nullIfBlank(String value) =>
      value.trim().isEmpty ? null : value;
}
