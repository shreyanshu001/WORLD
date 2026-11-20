import 'package:worlds/features/worlds/domain/content_block.dart';
import 'package:worlds/features/world_creation/domain/world_draft.dart';
import 'package:worlds/features/worlds/domain/world_status.dart';
import 'package:worlds/shared/models/geo_point.dart';
import 'package:worlds/shared/models/world_category.dart';

/// Converts drafts to and from the JSON of `save_world` and
/// `get_world_draft`. Each block type writes exactly the keys the server
/// accepts; there is no way to send an answer inside a block.
abstract final class WorldDraftCodec {
  static Map<String, Object?> toSaveJson(WorldDraft draft) => {
    'id': draft.id,
    'category': draft.category.name,
    'title': draft.title.trim(),
    'description': _nullIfBlank(draft.description),
    'cover_asset_id': draft.coverAssetId,
    'latitude': draft.location?.latitude,
    'longitude': draft.location?.longitude,
    'unlock_radius_meters': draft.unlockRadiusMeters,
    'blocks': [for (final block in draft.blocks) blockToJson(block)],
  };

  static Map<String, Object?> blockToJson(ContentBlock block) => {
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

  static WorldDraft fromServer(Map<String, dynamic> json) {
    final latitude = (json['latitude'] as num?)?.toDouble();
    final longitude = (json['longitude'] as num?)?.toDouble();
    return WorldDraft(
      id: json['id'] as String,
      category: WorldCategory.values.byName(json['category'] as String),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      coverAssetId: json['cover_asset_id'] as String?,
      location: latitude == null || longitude == null
          ? null
          : GeoPoint(latitude: latitude, longitude: longitude),
      unlockRadiusMeters:
          (json['unlock_radius_meters'] as num?)?.toInt() ??
          WorldDraft.defaultRadius,
      status: WorldStatus.values.byName(json['status'] as String),
      publishedAt: _date(json['published_at']),
      blocks: [
        for (final block in json['blocks'] as List<dynamic>? ?? const [])
          blockFromJson(block as Map<String, dynamic>),
      ],
      assets: [
        for (final asset in json['assets'] as List<dynamic>? ?? const [])
          WorldAsset(
            id: (asset as Map<String, dynamic>)['id'] as String,
            storagePath: asset['storage_path'] as String,
            mimeType: asset['mime_type'] as String,
          ),
      ],
    );
  }

  static ContentBlock blockFromJson(Map<String, dynamic> json) {
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

  static WorldSummary summaryFromRow(Map<String, dynamic> row) => WorldSummary(
    id: row['id'] as String,
    title: row['title'] as String,
    category: WorldCategory.values.byName(row['category'] as String),
    status: WorldStatus.values.byName(row['status'] as String),
    publishedAt: _date(row['published_at']),
    updatedAt: _date(row['updated_at'])!,
  );

  static String? _nullIfBlank(String value) =>
      value.trim().isEmpty ? null : value;

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.parse(value) : null;
}
